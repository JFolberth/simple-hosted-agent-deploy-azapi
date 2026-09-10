data "azapi_client_config" "current" {}

locals {
  effective_subscription_id                             = coalesce(var.subscription_id, data.azapi_client_config.current.subscription_id)
  acr_pull_role_definition_resource_id                  = "/subscriptions/${local.effective_subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${var.acr_pull_role_definition_id}"
  log_analytics_data_reader_role_definition_resource_id = "/subscriptions/${local.effective_subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${var.log_analytics_data_reader_role_definition_id}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Pattern     = "foundry-basic-runtime"
      Project     = "ProjectChopped"
      StackName   = var.stack_name
    },
    var.tags,
  )
}

# Establishes the subscription-scoped deployment boundary for the stack's Azure resources.
resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
  name      = "${var.stack_name}-${var.environment}-rg"
  location  = var.azure_location
  parent_id = "/subscriptions/${local.effective_subscription_id}"

  body = {
    tags = local.common_tags
  }
}

# Supplies a globally unique name suffix that remains stable while the stack and environment are unchanged.
resource "random_string" "stack_token" {
  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false

  keepers = {
    environment = var.environment
    stack_name  = var.stack_name
  }
}

module "log_analytics" {
  source = "./modules/log_analytics"

  location            = var.azure_location
  name                = "${var.stack_name}-${var.environment}-${random_string.stack_token.result}-log"
  resource_group_name = azapi_resource.resource_group.name
  subscription_id     = local.effective_subscription_id
  tags                = local.common_tags
}

module "application_insights" {
  source = "./modules/application_insights"

  location              = var.azure_location
  name                  = "${var.stack_name}-${var.environment}-${random_string.stack_token.result}-appi"
  resource_group_name   = azapi_resource.resource_group.name
  subscription_id       = local.effective_subscription_id
  tags                  = local.common_tags
  workspace_resource_id = module.log_analytics.id
}

module "foundry_account" {
  source = "./modules/foundry_account"

  account_kind        = var.foundry_account_kind
  account_name        = "${var.stack_name}-${var.environment}-${random_string.stack_token.result}-aif"
  account_sku_name    = var.foundry_account_sku_name
  deployments         = var.foundry_deployments
  location            = var.azure_location
  rai_policy          = var.foundry_rai_policy
  resource_group_name = azapi_resource.resource_group.name
  subscription_id     = local.effective_subscription_id
  tags                = local.common_tags
}

module "foundry_project" {
  source = "./modules/foundry_project"

  account_id                      = module.foundry_account.id
  description                     = var.agent_description
  display_name                    = var.agent_name
  foundry_user_role_definition_id = var.foundry_user_role_definition_id
  location                        = var.azure_location
  project_name                    = "${var.stack_name}-${var.environment}-${random_string.stack_token.result}-proj"
  subscription_id                 = local.effective_subscription_id
  tags                            = local.common_tags
}

module "image_registry" {
  source = "./modules/image_registry"

  location            = var.azure_location
  name                = "${replace(var.stack_name, "-", "")}${var.environment}${random_string.stack_token.result}cr"
  resource_group_name = azapi_resource.resource_group.name
  sku_name            = "Standard"
  subscription_id     = local.effective_subscription_id
  tags                = local.common_tags
}

# Lets the project identity pull hosted-agent images without enabling registry admin credentials.
resource "azapi_resource" "project_acr_pull_role" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${module.image_registry.id}/${module.foundry_project.principal_id}/${var.acr_pull_role_definition_id}")
  parent_id = module.image_registry.id

  body = {
    properties = {
      principalId      = module.foundry_project.principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.acr_pull_role_definition_resource_id
    }
  }
}

# Gives the project identity read access to application telemetry at the Application Insights scope.
resource "azapi_resource" "project_log_analytics_reader_role" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${module.application_insights.id}/${module.foundry_project.principal_id}/${var.log_analytics_data_reader_role_definition_id}")
  parent_id = module.application_insights.id

  body = {
    properties = {
      principalId      = module.foundry_project.principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.log_analytics_data_reader_role_definition_resource_id
    }
  }
}

module "foundry_connection_appinsights" {
  source = "./modules/foundry_connection"

  auth_type        = "ApiKey"
  category         = "AppInsights"
  connection_name  = var.application_insights_connection_name
  credentials      = { key = module.application_insights.connection_string }
  is_shared_to_all = true
  metadata = {
    ApiType    = "Azure"
    ResourceId = module.application_insights.id
  }
  project_id = module.foundry_project.id
  target_id  = module.application_insights.id

  # The connection body does not reference RBAC, so enforce authorization-first creation.
  depends_on = [azapi_resource.project_log_analytics_reader_role]
}

module "foundry_connection_registry" {
  source = "./modules/foundry_connection"

  auth_type       = "ManagedIdentity"
  category        = "ContainerRegistry"
  connection_name = var.foundry_project_connection_name
  credentials = {
    clientId   = module.foundry_project.principal_id
    resourceId = module.image_registry.id
  }
  is_shared_to_all = true
  metadata         = { ResourceId = module.image_registry.id }
  project_id       = module.foundry_project.id
  target_id        = module.image_registry.login_server

  # The project identity authenticates this connection and needs AcrPull before it is usable.
  depends_on = [azapi_resource.project_acr_pull_role]
}

module "hosted_agent" {
  source = "./modules/hosted_agent"

  agent_name            = var.agent_name
  environment_variables = var.environment_variables
  image_uri             = "${module.image_registry.login_server}/${var.image_repository_name}:${var.image_tag}"
  model_deployment_name = module.foundry_account.primary_deployment_name
  project_endpoint      = module.foundry_project.project_endpoint
  rai_policy_id         = module.foundry_account.rai_policy_id

  # ACR pull authorization is an operational prerequisite not represented in the agent request body.
  depends_on = [azapi_resource.project_acr_pull_role]
}

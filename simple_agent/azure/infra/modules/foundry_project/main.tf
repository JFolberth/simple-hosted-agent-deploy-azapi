terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

locals {
  foundry_user_role_definition_resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${var.foundry_user_role_definition_id}"
}

# Creates the identity-bearing workspace that owns connections and hosted agents beneath the Foundry account.
resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2026-03-01"
  name      = var.project_name
  location  = var.location
  parent_id = var.account_id
  # AzAPI's schema trails the 2026 project contract; ARM still validates the request.
  schema_validation_enabled = false

  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      description = var.description
      displayName = var.display_name
    }
    tags = var.tags
  }

  response_export_values = [
    "id",
    "name",
    "properties.endpoints",
    "identity.principalId"
  ]
}

# Grants the project identity model access at its parent Foundry account scope.
# A deterministic assignment name prevents replacement churn for this identity grant.
resource "azapi_resource" "project_openai_user_role" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${var.account_id}/${azapi_resource.project.output.identity.principalId}/${var.foundry_user_role_definition_id}")
  parent_id = var.account_id

  body = {
    properties = {
      principalId      = azapi_resource.project.output.identity.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.foundry_user_role_definition_resource_id
    }
  }
}

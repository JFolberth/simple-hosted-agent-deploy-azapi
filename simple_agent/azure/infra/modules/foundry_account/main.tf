terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

locals {
  deployments_by_name = {
    for deployment in var.deployments : deployment.name => deployment
  }
}

# Hosts Foundry projects, model deployments, and content filtering under a managed identity.
# Local key authentication is disabled, while the account remains reachable over its public endpoint.
resource "azapi_resource" "account" {
  type      = "Microsoft.CognitiveServices/accounts@2026-03-01"
  name      = var.account_name
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  # AzAPI's schema trails these 2026 Foundry fields; ARM still validates the request.
  schema_validation_enabled = false

  body = {
    identity = {
      type = "SystemAssigned"
    }
    kind = var.account_kind
    properties = {
      allowProjectManagement = true
      customSubDomainName    = var.account_name
      disableLocalAuth       = true
      networkAcls = {
        defaultAction       = "Allow"
        ipRules             = []
        virtualNetworkRules = []
      }
      publicNetworkAccess = "Enabled"
    }
    sku = {
      name = var.account_sku_name
    }
    tags = var.tags
  }

  response_export_values = [
    "id",
    "name",
    "identity.principalId",
    "properties.endpoint"
  ]
}

# Defines the content filtering policy shared by model deployments and the hosted agent.
resource "azapi_resource" "rai_policy" {
  type      = "Microsoft.CognitiveServices/accounts/raiPolicies@2026-03-01"
  name      = var.rai_policy.name
  parent_id = azapi_resource.account.id

  body = {
    properties = {
      basePolicyName = var.rai_policy.base_policy_name
      contentFilters = [
        for filter in var.rai_policy.content_filters : {
          blocking          = filter.blocking
          enabled           = filter.enabled
          name              = filter.name
          severityThreshold = filter.severity_threshold
          source            = filter.source
        }
      ]
      mode = var.rai_policy.mode
    }
    tags = var.tags
  }

  lifecycle {
    # Azure asynchronously appends platform-managed filters (DefenderForAI, Indirect Attack); don't fight that drift.
    ignore_changes = [body.properties.contentFilters]
  }
}

# Provisions each configured model endpoint and binds it to the account's content filtering policy.
resource "azapi_resource" "deployment" {
  for_each = local.deployments_by_name

  type      = "Microsoft.CognitiveServices/accounts/deployments@2026-03-01"
  name      = each.value.name
  parent_id = azapi_resource.account.id
  # AzAPI's schema trails these 2026 model and RAI fields; ARM validates the request.
  schema_validation_enabled = false

  body = {
    properties = {
      model = {
        format  = each.value.model_format
        name    = each.value.model_name
        version = each.value.model_version
      }
      raiPolicyName = azapi_resource.rai_policy.name
    }
    sku = {
      capacity = each.value.sku_capacity
      name     = each.value.sku_name
    }
    tags = var.tags
  }
}

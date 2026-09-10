terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

# Centralizes retained application telemetry consumed through the workspace-based monitoring path.
resource "azapi_resource" "workspace" {
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  name      = var.name
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  body = {
    properties = {
      retentionInDays = var.retention_in_days
      sku = {
        name = "PerGB2018"
      }
    }
    tags = var.tags
  }

  response_export_values = [
    "id",
    "name",
    "properties.customerId"
  ]
}

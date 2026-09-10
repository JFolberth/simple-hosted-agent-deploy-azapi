terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

# Routes application telemetry into the shared Log Analytics workspace for Foundry observability.
resource "azapi_resource" "component" {
  type      = "Microsoft.Insights/components@2020-02-02"
  name      = var.name
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  body = {
    kind = "web"
    properties = {
      Application_Type    = "web"
      Flow_Type           = "Bluefield"
      IngestionMode       = "LogAnalytics"
      Request_Source      = "rest"
      WorkspaceResourceId = var.workspace_resource_id
    }
    tags = var.tags
  }

  response_export_values = [
    "id",
    "name",
    "properties.ConnectionString",
    "properties.InstrumentationKey"
  ]
}

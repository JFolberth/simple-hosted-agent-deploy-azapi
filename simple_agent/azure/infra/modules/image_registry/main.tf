terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

# Stores hosted-agent images with admin credentials disabled; public network access remains enabled.
resource "azapi_resource" "registry" {
  type      = "Microsoft.ContainerRegistry/registries@2025-11-01"
  name      = var.name
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  body = {
    properties = {
      adminUserEnabled    = false
      publicNetworkAccess = "Enabled"
    }
    sku = {
      name = var.sku_name
    }
    tags = var.tags
  }

  response_export_values = [
    "id",
    "name",
    "properties.loginServer"
  ]
}

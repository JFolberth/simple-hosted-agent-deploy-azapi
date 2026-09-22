terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

# Registers an external service endpoint and its authentication settings as a project-scoped integration.
resource "azapi_resource" "connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-03-01"
  name      = var.connection_name
  parent_id = var.project_id
  # Connection readback omits/adds service-managed fields; tolerate that API drift.
  ignore_missing_property   = true
  ignore_null_property      = true
  schema_validation_enabled = false

  body = {
    properties = {
      authType      = var.auth_type
      category      = var.category
      credentials   = var.credentials
      isSharedToAll = var.is_shared_to_all
      metadata      = var.metadata
      target        = var.target_id
    }
  }

  response_export_values = [
    "id",
    "name"
  ]

  lifecycle {
    # The read-back briefly lags the write; ignore it instead of re-applying every plan.
    ignore_changes = [body.properties.isSharedToAll]
  }
}

output "customer_id" {
  description = "Workspace customer ID."
  value       = azapi_resource.workspace.output.properties.customerId
}

output "id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azapi_resource.workspace.id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = azapi_resource.workspace.name
}

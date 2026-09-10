output "id" {
  description = "Resource ID of the Foundry project."
  value       = azapi_resource.project.id
}

output "name" {
  description = "Name of the Foundry project."
  value       = azapi_resource.project.name
}

output "project_endpoint" {
  description = "API endpoint URL of the Foundry project."
  value = coalesce(
    try(azapi_resource.project.output.properties.endpoints["AI Foundry API"], null),
    try(azapi_resource.project.output.properties.endpoints.apiEndpoint, null),
    try(azapi_resource.project.output.properties.endpoints.endpoint, null),
  )
}

output "principal_id" {
  description = "System-assigned managed identity principal ID for the Foundry project."
  value       = azapi_resource.project.output.identity.principalId
}

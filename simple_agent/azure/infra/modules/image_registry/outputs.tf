output "id" {
  description = "Resource ID of the Azure Container Registry."
  value       = azapi_resource.registry.id
}

output "login_server" {
  description = "ACR login server."
  value       = azapi_resource.registry.output.properties.loginServer
}

output "name" {
  description = "Name of the Azure Container Registry."
  value       = azapi_resource.registry.name
}

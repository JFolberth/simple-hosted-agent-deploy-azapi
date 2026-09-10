output "connection_string" {
  description = "Application Insights connection string."
  value       = azapi_resource.component.output.properties.ConnectionString
}

output "id" {
  description = "Resource ID of Application Insights."
  value       = azapi_resource.component.id
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = azapi_resource.component.output.properties.InstrumentationKey
}

output "name" {
  description = "Name of Application Insights."
  value       = azapi_resource.component.name
}

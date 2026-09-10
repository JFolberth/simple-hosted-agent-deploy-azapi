output "endpoint" {
  description = "Endpoint of the Foundry account."
  value       = azapi_resource.account.output.properties.endpoint
}

output "id" {
  description = "Resource ID of the Foundry account."
  value       = azapi_resource.account.id
}

output "name" {
  description = "Name of the Foundry account."
  value       = azapi_resource.account.name
}

output "primary_deployment_name" {
  description = "Name of the primary model deployment used by the hosted agent."
  value       = azapi_resource.deployment[var.deployments[0].name].name
}

output "principal_id" {
  description = "System-assigned managed identity principal ID for the Foundry account."
  value       = azapi_resource.account.output.identity.principalId
}

output "rai_policy_id" {
  description = "Full ARM resource ID of the account-scoped RAI policy."
  value       = azapi_resource.rai_policy.id
}

output "acr_id" {
  description = "Resource ID of the Azure Container Registry."
  value       = module.image_registry.id
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry."
  value       = module.image_registry.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry."
  value       = module.image_registry.name
}

output "agent_name" {
  description = "Name shared by the Foundry project and the hosted agent deployed against it."
  value       = var.agent_name
}

output "application_insights_connection_string" {
  description = "Application Insights connection string."
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "application_insights_id" {
  description = "Resource ID of Application Insights component."
  value       = module.application_insights.id
}

output "foundry_account_endpoint" {
  description = "Endpoint URL of the Foundry account."
  value       = module.foundry_account.endpoint
}

output "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  value       = module.foundry_account.id
}

output "foundry_project_endpoint" {
  description = "Data-plane endpoint URL of the Foundry project."
  value       = module.foundry_project.project_endpoint
}

output "foundry_project_id" {
  description = "Resource ID of the Foundry project."
  value       = module.foundry_project.id
}

output "foundry_project_name" {
  description = "Name of the Foundry project."
  value       = module.foundry_project.name
}

output "foundry_rai_policy_id" {
  description = "Full ARM resource ID of the account-scoped RAI policy."
  value       = module.foundry_account.rai_policy_id
}

output "model_deployment_name" {
  description = "Model deployment name used for hosted agent versions."
  value       = module.foundry_account.primary_deployment_name
}

output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azapi_resource.resource_group.name
}

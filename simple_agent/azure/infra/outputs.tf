output "acr_id" {
  description = "Resource ID of the Azure Container Registry."
  value       = module.image_registry.id
}

output "acr_login_server" {
  description = "Login server for Azure Container Registry."
  value       = module.image_registry.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry."
  value       = module.image_registry.name
}

output "acr_repository" {
  description = "Container repository path used for the hosted image."
  value       = "${module.image_registry.login_server}/${var.image_repository_name}"
}

output "acr_repository_name" {
  description = "Container repository name inside ACR."
  value       = var.image_repository_name
}

output "application_insights_connection_string" {
  description = "Application Insights connection string."
  value       = module.application_insights.connection_string
}

output "application_insights_id" {
  description = "Resource ID of Application Insights component."
  value       = module.application_insights.id
}

output "container_image_uri" {
  description = "Fully qualified URI of the image built and pushed to ACR."
  value       = module.image_build.image_uri
}

output "foundry_account_endpoint" {
  description = "Endpoint URL of the Foundry account."
  value       = module.foundry_account.endpoint
}

output "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  value       = module.foundry_account.id
}

output "foundry_hosted_agent_id" {
  description = "Data-plane resource ID of the logical Foundry hosted agent."
  value       = module.hosted_agent.id
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
  value       = var.foundry_deployments[0].name
}

output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azapi_resource.resource_group.name
}

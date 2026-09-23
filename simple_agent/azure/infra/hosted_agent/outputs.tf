output "foundry_hosted_agent_id" {
  description = "Data-plane resource ID of the logical Foundry hosted agent."
  value       = module.hosted_agent.id
}

output "image_uri" {
  description = "Fully qualified image URI deployed to the hosted agent."
  value       = local.image_uri
}

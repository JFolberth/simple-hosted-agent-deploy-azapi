locals {
  image_uri = "${var.acr_login_server}/${var.image_repository_name}:${var.image_tag}"
}

module "hosted_agent" {
  source = "../modules/hosted_agent"

  agent_name            = var.agent_name
  cpu                   = var.cpu
  environment_variables = var.environment_variables
  image_uri             = local.image_uri
  memory                = var.memory
  model_deployment_name = var.model_deployment_name
  project_endpoint      = var.project_endpoint
  rai_policy_id         = var.rai_policy_id
}

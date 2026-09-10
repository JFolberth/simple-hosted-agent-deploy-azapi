# Publishes the container-backed logical agent; Foundry owns its generated version history.
resource "azapi_data_plane_resource" "hosted_agent" {
  type = "Microsoft.Foundry/agents@v1"
  name = var.agent_name
  # AzAPI data-plane parents use the endpoint host/path without a URI scheme.
  parent_id = trimprefix(var.project_endpoint, "https://")

  body = {
    name = var.agent_name
    definition = {
      kind = "hosted"
      container_configuration = {
        image = var.image_uri
      }
      cpu    = "0.25"
      memory = "0.5Gi"
      protocol_versions = [
        {
          # The hosted container must implement this Foundry Responses contract.
          protocol = "responses"
          version  = "2.0.0"
        }
      ]
      environment_variables = merge(var.environment_variables, {
        AZURE_AI_MODEL_DEPLOYMENT_NAME = var.model_deployment_name
      })
      rai_config = {
        # Hosted agents require the full policy ARM ID; model deployments use its name.
        rai_policy_name = var.rai_policy_id
      }
    }
  }
}

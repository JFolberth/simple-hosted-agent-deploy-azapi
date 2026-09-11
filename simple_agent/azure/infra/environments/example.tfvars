agent_name     = "BasicAgent"
azure_location = "eastus2"
environment    = "dev"
image_tag      = "replace-at-deploy-time"
stack_name     = "azapi-agent-deploy"

foundry_deployments = [
  {
    model_format  = "OpenAI"
    model_name    = "gpt-4.1-mini"
    model_version = "2025-04-14"
    name          = "gpt-4.1-mini"
    sku_capacity  = 10
    sku_name      = "Standard"
  }
]

foundry_rai_policy = {
  base_policy_name = "Microsoft.Default"
  mode             = "Blocking"
  name             = "azapi-agent-deploy-content-safety"
  content_filters = [
    { name = "Hate", source = "Prompt", enabled = true, blocking = true, severity_threshold = "Medium" },
    { name = "Hate", source = "Completion", enabled = true, blocking = true, severity_threshold = "Medium" },
    { name = "Sexual", source = "Prompt", enabled = true, blocking = true, severity_threshold = "Medium" },
    { name = "Sexual", source = "Completion", enabled = true, blocking = true, severity_threshold = "Medium" },
    { name = "Selfharm", source = "Prompt", enabled = true, blocking = true, severity_threshold = "Medium" },
    { name = "Selfharm", source = "Completion", enabled = true, blocking = true, severity_threshold = "Medium" },
    { name = "Violence", source = "Prompt", enabled = true, blocking = true, severity_threshold = "Medium" },
    { name = "Violence", source = "Completion", enabled = true, blocking = true, severity_threshold = "Medium" },
  ]
}

tags = {
  Owner = "team-ai"
}

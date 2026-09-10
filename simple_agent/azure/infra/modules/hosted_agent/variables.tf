variable "agent_name" {
  description = "Name of the logical Foundry hosted agent."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.agent_name) != ""
    error_message = "agent_name must not be empty."
  }
}

variable "environment_variables" {
  description = "Environment variables supplied to the hosted runtime container."
  type        = map(string)
  nullable    = false
}

variable "image_uri" {
  description = "Complete immutable container image URI for the hosted runtime."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.image_uri) != "" && !endswith(var.image_uri, ":latest")
    error_message = "image_uri must specify a non-empty immutable image and must not use the latest tag."
  }
}

variable "model_deployment_name" {
  description = "Foundry model deployment name exposed to the hosted runtime."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.model_deployment_name) != ""
    error_message = "model_deployment_name must not be empty."
  }
}

variable "project_endpoint" {
  description = "Data-plane endpoint URL of the parent Foundry project."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^https://.+", var.project_endpoint))
    error_message = "project_endpoint must be a non-empty HTTPS URL."
  }
}

variable "rai_policy_id" {
  description = "Full ARM resource ID of the RAI policy applied to the hosted agent."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+/raiPolicies/[^/]+$", var.rai_policy_id))
    error_message = "rai_policy_id must be a full Cognitive Services RAI policy resource ID."
  }
}

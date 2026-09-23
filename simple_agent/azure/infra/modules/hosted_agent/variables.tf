variable "agent_name" {
  description = "Name of the logical Foundry hosted agent."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.agent_name) != ""
    error_message = "agent_name must not be empty."
  }
}

variable "cpu" {
  description = "CPU cores allocated to the hosted runtime container (for example \"0.25\")."
  type        = string
  default     = "0.25"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?$", var.cpu))
    error_message = "cpu must be a plain number string, for example 0.25 or 1."
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

variable "memory" {
  description = "Memory allocated to the hosted runtime container (for example \"0.5Gi\")."
  type        = string
  default     = "0.5Gi"
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.memory))
    error_message = "memory must be a Gi-suffixed number string, for example 0.5Gi or 2Gi."
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

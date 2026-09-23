variable "acr_login_server" {
  description = "Login server of the ACR created by the foundry_base stack (its acr_login_server output)."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.acr_login_server) != ""
    error_message = "acr_login_server must not be empty."
  }
}

variable "agent_name" {
  description = "Name of the logical Foundry hosted agent (the foundry_base stack's agent_name output)."
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
  description = "Additional environment variables supplied to the hosted runtime container."
  type        = map(string)
  default     = {}
}

variable "image_repository_name" {
  description = "Repository name inside ACR that holds the built image. Must match the tag pushed by the CLI build step."
  type        = string
  default     = "basic-agent"

  validation {
    condition     = can(regex("^[a-z0-9]+([._-][a-z0-9]+)*$", var.image_repository_name))
    error_message = "image_repository_name must use lowercase letters, numbers, and separators . _ -."
  }
}

variable "image_tag" {
  description = "Immutable container image tag already built and pushed to ACR (for example a git SHA). 'latest' is rejected."
  type        = string
  nullable    = false

  validation {
    condition     = var.image_tag != "latest" && can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.image_tag))
    error_message = "image_tag must be a valid immutable Docker tag (for example a git SHA). 'latest' is not permitted."
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
  description = "Foundry model deployment name exposed to the hosted runtime (the foundry_base stack's model_deployment_name output)."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.model_deployment_name) != ""
    error_message = "model_deployment_name must not be empty."
  }
}

variable "project_endpoint" {
  description = "Data-plane endpoint URL of the parent Foundry project (the foundry_base stack's foundry_project_endpoint output)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^https://.+", var.project_endpoint))
    error_message = "project_endpoint must be a non-empty HTTPS URL."
  }
}

variable "rai_policy_id" {
  description = "Full ARM resource ID of the RAI policy applied to the hosted agent (the foundry_base stack's foundry_rai_policy_id output)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+/raiPolicies/[^/]+$", var.rai_policy_id))
    error_message = "rai_policy_id must be a full Cognitive Services RAI policy resource ID."
  }
}

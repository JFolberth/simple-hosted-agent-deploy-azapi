variable "acr_pull_role_definition_id" {
  description = "Built-in role definition GUID for AcrPull."
  type        = string
  default     = "7f951dda-4ed3-4680-a7ca-43fe172d538d"

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.acr_pull_role_definition_id))
    error_message = "acr_pull_role_definition_id must be a valid GUID."
  }
}

variable "agent_description" {
  description = "Human readable description for the Foundry project."
  type        = string
  default     = "Basic hosted agent runtime provisioned via Terraform."
}

variable "agent_name" {
  description = "Name used for the Foundry project and the hosted agent deployed against it."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{1,47}$", var.agent_name))
    error_message = "agent_name must start with a letter, be 2-48 characters, and contain only alphanumerics, underscores, or hyphens."
  }
}

variable "application_insights_connection_name" {
  description = "Connection name used inside the Foundry project for Application Insights."
  type        = string
  default     = "appinsights-connection"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,32}$", var.application_insights_connection_name))
    error_message = "application_insights_connection_name must be 3-33 characters and contain alphanumerics, underscores, or hyphens."
  }
}

variable "azure_location" {
  description = "Azure region where resources are deployed."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+[a-z0-9-]*[a-z0-9]+$", var.azure_location))
    error_message = "azure_location must be a valid Azure location name (for example: eastus2)."
  }
}

variable "environment" {
  description = "Deployment environment identifier (for example: dev, staging, prod)."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "foundry_account_kind" {
  description = "Cognitive Services account kind used for Foundry."
  type        = string
  default     = "AIServices"
}

variable "foundry_account_sku_name" {
  description = "SKU name for the Foundry account."
  type        = string
  default     = "S0"
}

variable "foundry_deployments" {
  description = "Model deployments to create under the Foundry account."
  type = list(object({
    model_format  = string
    model_name    = string
    model_version = string
    name          = string
    sku_capacity  = number
    sku_name      = string
  }))
  nullable = false

  validation {
    condition     = length(var.foundry_deployments) > 0
    error_message = "foundry_deployments must include at least one deployment object."
  }
}

variable "foundry_project_connection_name" {
  description = "Connection name used inside the Foundry project for the container registry."
  type        = string
  default     = "acr-connection"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,32}$", var.foundry_project_connection_name))
    error_message = "foundry_project_connection_name must be 3-33 characters and contain alphanumerics, underscores, or hyphens."
  }
}

variable "foundry_rai_policy" {
  description = "Account-scoped RAI policy applied to model deployments and hosted agents."
  type = object({
    base_policy_name = string
    content_filters = list(object({
      blocking           = bool
      enabled            = bool
      name               = string
      severity_threshold = string
      source             = string
    }))
    mode = string
    name = string
  })
  nullable = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]*$", var.foundry_rai_policy.name))
    error_message = "foundry_rai_policy.name must start with an alphanumeric character and contain only alphanumerics, underscores, periods, or hyphens."
  }

  validation {
    condition     = contains(["Asynchronous_filter", "Blocking", "Default", "Deferred"], var.foundry_rai_policy.mode)
    error_message = "foundry_rai_policy.mode must be one of: Asynchronous_filter, Blocking, Default, Deferred."
  }

  validation {
    condition = alltrue([
      for filter in var.foundry_rai_policy.content_filters :
      contains(["Hate", "Sexual", "Selfharm", "Violence"], filter.name) &&
      contains(["Prompt", "Completion"], filter.source) &&
      contains(["Low", "Medium", "High"], filter.severity_threshold)
    ])
    error_message = "Each content filter must use a standard harm category, Prompt or Completion source, and Low, Medium, or High severity threshold."
  }
}

variable "foundry_user_role_definition_id" {
  description = "Built-in role definition GUID for Foundry User."
  type        = string
  default     = "53ca6127-db72-4b80-b1b0-d745d6d5456d"

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.foundry_user_role_definition_id))
    error_message = "foundry_user_role_definition_id must be a valid GUID."
  }
}

variable "log_analytics_data_reader_role_definition_id" {
  description = "Built-in role definition GUID for Log Analytics Data Reader."
  type        = string
  default     = "73c42c96-874c-492b-b04d-ab87d138a893"

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.log_analytics_data_reader_role_definition_id))
    error_message = "log_analytics_data_reader_role_definition_id must be a valid GUID."
  }
}

variable "stack_name" {
  description = "Stack name used as a prefix for resource naming."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,31}$", var.stack_name))
    error_message = "stack_name must be lowercase alphanumeric with hyphens, 2-32 characters."
  }
}

variable "subscription_id" {
  description = "Optional Azure subscription ID override. If null, the current az login subscription is used."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be null or a valid GUID."
  }
}

variable "tags" {
  description = "Additional tags merged with default tags."
  type        = map(string)
  default     = {}
}

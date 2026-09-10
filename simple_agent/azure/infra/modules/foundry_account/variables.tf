variable "account_kind" {
  description = "Kind of the Foundry Cognitive Services account."
  type        = string
  default     = "AIServices"
}

variable "account_name" {
  description = "Foundry account name."
  type        = string
  nullable    = false
}

variable "account_sku_name" {
  description = "SKU name for the Foundry account."
  type        = string
  default     = "S0"
}

variable "deployments" {
  description = "Model deployments created under the Foundry account."
  type = list(object({
    model_format  = string
    model_name    = string
    model_version = string
    name          = string
    sku_capacity  = number
    sku_name      = string
  }))
  nullable = false
}

variable "location" {
  description = "Azure location for the Foundry account."
  type        = string
  nullable    = false
}

variable "rai_policy" {
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
}

variable "resource_group_name" {
  description = "Name of the resource group where the Foundry account is created."
  type        = string
  nullable    = false
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags for Foundry resources."
  type        = map(string)
  default     = {}
}

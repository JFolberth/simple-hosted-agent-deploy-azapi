variable "location" {
  description = "Azure location for the Log Analytics workspace."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Log Analytics workspace name."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group where the workspace is created."
  type        = string
  nullable    = false
}

variable "retention_in_days" {
  description = "Retention period for logs in days."
  type        = number
  default     = 30
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags for the workspace resource."
  type        = map(string)
  default     = {}
}

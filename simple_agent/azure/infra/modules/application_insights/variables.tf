variable "location" {
  description = "Azure location for Application Insights."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Application Insights component name."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group where Application Insights is created."
  type        = string
  nullable    = false
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags for the Application Insights resource."
  type        = map(string)
  default     = {}
}

variable "workspace_resource_id" {
  description = "Resource ID of the linked Log Analytics workspace."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure location for the container registry."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Azure Container Registry name."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group where the registry is created."
  type        = string
  nullable    = false
}

variable "sku_name" {
  description = "SKU name for the registry."
  type        = string
  default     = "Standard"
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags for the registry resource."
  type        = map(string)
  default     = {}
}

variable "account_id" {
  description = "Resource ID of the parent Foundry account."
  type        = string
  nullable    = false
}

variable "description" {
  description = "Description for the Foundry project."
  type        = string
  default     = "Basic hosted agent project."
}

variable "display_name" {
  description = "Display name for the Foundry project."
  type        = string
  nullable    = false
}

variable "foundry_user_role_definition_id" {
  description = "Role definition GUID for Foundry User."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure location for the Foundry project."
  type        = string
  nullable    = false
}

variable "project_name" {
  description = "Foundry project name."
  type        = string
  nullable    = false
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags for the Foundry project."
  type        = map(string)
  default     = {}
}

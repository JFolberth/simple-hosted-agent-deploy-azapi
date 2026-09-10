variable "auth_type" {
  description = "Authentication type used for the connection."
  type        = string
  default     = "AAD"
}

variable "category" {
  description = "Connection category used by Foundry."
  type        = string
  nullable    = false
}

variable "connection_name" {
  description = "Foundry connection name."
  type        = string
  nullable    = false
}

variable "credentials" {
  description = "Optional credentials payload for the connection."
  type        = map(string)
  default     = {}
}

variable "is_shared_to_all" {
  description = "Whether the connection is shared to all project members."
  type        = bool
  default     = false
}

variable "metadata" {
  description = "Optional metadata for the connection."
  type        = map(string)
  default     = {}
}

variable "project_id" {
  description = "Resource ID of the parent Foundry project."
  type        = string
  nullable    = false
}

variable "target_id" {
  description = "Target resource ID used by the connection."
  type        = string
  nullable    = false
}

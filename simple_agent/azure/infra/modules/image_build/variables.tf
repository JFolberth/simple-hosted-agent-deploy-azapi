variable "build_context_path" {
  description = "Local directory uploaded to ACR as the Docker build context."
  type        = string
  nullable    = false

  validation {
    condition     = fileexists("${var.build_context_path}/Dockerfile")
    error_message = "build_context_path must contain a Dockerfile."
  }
}

variable "image_repository_name" {
  description = "Repository name inside ACR for the built image."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+([._-][a-z0-9]+)*$", var.image_repository_name))
    error_message = "image_repository_name must use lowercase letters, numbers, and separators . _ -."
  }
}

variable "image_tag" {
  description = "Immutable tag assigned to the built image."
  type        = string
  nullable    = false

  validation {
    condition     = var.image_tag != "latest" && can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.image_tag))
    error_message = "image_tag must be a valid non-latest Docker tag."
  }
}

variable "registry_id" {
  description = "Resource ID of the target Azure Container Registry."
  type        = string
  nullable    = false
}

variable "registry_login_server" {
  description = "Login server of the target Azure Container Registry."
  type        = string
  nullable    = false
}

variable "registry_name" {
  description = "Name of the target Azure Container Registry."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group containing the registry."
  type        = string
  nullable    = false
}

variable "subscription_id" {
  description = "Azure subscription containing the registry."
  type        = string
  nullable    = false
}

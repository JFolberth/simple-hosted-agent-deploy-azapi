terraform {
  required_version = ">= 1.9"

  backend "local" {}

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.9.0, < 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azapi" {
}

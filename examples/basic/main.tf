terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "management_group" {
  source = "../.."

  name         = "example-platform"
  display_name = "Example Platform"
}

output "management_group_id" {
  value = module.management_group.id
}

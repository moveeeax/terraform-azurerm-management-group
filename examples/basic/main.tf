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

# Nesting: `parent_management_group_id` needs the full resource ID, which is
# exactly what the parent module's `id` output is. A bare "example-platform"
# would be rejected by the provider.
module "child_management_group" {
  source = "../.."

  name                       = "example-platform-workloads"
  display_name               = "Example Platform Workloads"
  parent_management_group_id = module.management_group.id
}

output "management_group_id" {
  value = module.management_group.id
}

output "child_management_group_id" {
  value = module.child_management_group.id
}

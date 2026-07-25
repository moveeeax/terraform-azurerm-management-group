# Test-suite only: `mock_provider` requires Terraform >= 1.7 / OpenTofu >= 1.7.
# The module itself still supports >= 1.5 (see versions.tf) — do not raise
# required_version for the sake of these tests.

mock_provider "azurerm" {}

variables {
  name         = "example-platform"
  display_name = "Example Platform"
}

# --- defaults ---------------------------------------------------------------
#
# `parent_management_group_id` and `subscription_ids` are Optional+Computed on
# the resource, so when they are left unset the plan value is unknown and cannot
# be asserted on. What the defaults run proves is that a name and a display name
# are enough to plan, and that both reach the provider unchanged.

run "name_and_display_name_are_enough_and_stay_distinct" {
  command = plan

  assert {
    condition     = azurerm_management_group.this.name == "example-platform"
    error_message = "name must reach the provider verbatim — it is the resource ID segment."
  }

  assert {
    condition     = azurerm_management_group.this.display_name == "Example Platform"
    error_message = "display_name must reach the provider verbatim — it is the portal label."
  }
}

run "subscription_ids_defaults_to_null_not_an_empty_set" {
  command = plan

  # `subscription_ids` is authoritative and the provider documents an empty list
  # as "clear all Subscriptions from the Management Group". The default must
  # therefore leave the attribute unset, so that a module that was never asked
  # to manage subscription placement cannot de-associate a live subscription and
  # dump it into the tenant root group.
  assert {
    condition     = var.subscription_ids == null
    error_message = "subscription_ids must default to null (attribute unset), never to [] (clear all subscriptions)."
  }
}

# --- name is the ID segment, not the portal label ---------------------------

run "rejects_a_display_name_style_value_for_name" {
  command = plan

  variables {
    name = "Example Platform"
  }

  # A space is legal in display_name and illegal in name. Without this check the
  # mistake only surfaces from the provider, after the rest of the plan is built.
  expect_failures = [var.name]
}

run "rejects_a_name_longer_than_azure_allows" {
  command = plan

  variables {
    name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  expect_failures = [var.name]
}

run "accepts_the_full_azure_name_charset" {
  command = plan

  variables {
    name = "corp.platform_(prod)-01"
  }

  assert {
    condition     = azurerm_management_group.this.name == "corp.platform_(prod)-01"
    error_message = "The validation must not reject characters Azure itself allows in a management group name."
  }
}

run "rejects_an_empty_display_name" {
  command = plan

  variables {
    display_name = "   "
  }

  expect_failures = [var.display_name]
}

# --- parent must be a full resource ID, not a bare group name ---------------

run "rejects_a_bare_parent_group_name" {
  command = plan

  variables {
    parent_management_group_id = "platform"
  }

  # The provider only says `Unable to parse Management Group ID "platform"`;
  # the variable validation names the expected format instead.
  expect_failures = [var.parent_management_group_id]
}

run "rejects_a_subscription_scope_as_the_parent" {
  command = plan

  variables {
    parent_management_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_management_group_id]
}

run "accepts_a_full_parent_management_group_id" {
  command = plan

  variables {
    parent_management_group_id = "/providers/Microsoft.Management/managementGroups/corp"
  }

  assert {
    condition     = azurerm_management_group.this.parent_management_group_id == "/providers/Microsoft.Management/managementGroups/corp"
    error_message = "A well-formed parent ID must be passed through untouched."
  }
}

# --- subscription_ids are bare GUIDs ----------------------------------------

run "rejects_a_subscription_resource_id_instead_of_a_guid" {
  command = plan

  variables {
    subscription_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
  }

  # The provider's own IsUUID check would catch this, but only after the plan
  # is walked, and the error does not say what the right shape is.
  expect_failures = [var.subscription_ids]
}

run "rejects_a_subscription_display_name" {
  command = plan

  variables {
    subscription_ids = ["prod-subscription"]
  }

  expect_failures = [var.subscription_ids]
}

run "accepts_bare_subscription_guids" {
  command = plan

  variables {
    subscription_ids = [
      "00000000-0000-0000-0000-000000000000",
      "11111111-1111-1111-1111-111111111111",
    ]
  }

  assert {
    condition     = length(azurerm_management_group.this.subscription_ids) == 2
    error_message = "Every configured subscription must reach the provider — any that does not would be de-associated and moved to the tenant root group."
  }

  assert {
    condition     = contains(azurerm_management_group.this.subscription_ids, "11111111-1111-1111-1111-111111111111")
    error_message = "subscription_ids must be passed through as-is."
  }
}

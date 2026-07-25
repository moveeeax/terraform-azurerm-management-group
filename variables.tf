variable "display_name" {
  description = <<-EOT
    Human-readable display name shown in the portal. Unlike `name` this may
    contain spaces, is not part of the management group's resource ID, and can
    be changed in place without recreating the group.
  EOT

  type = string

  validation {
    condition     = length(trimspace(var.display_name)) > 0
    error_message = "display_name must not be empty or whitespace only."
  }
}

variable "name" {
  description = <<-EOT
    Name (ID) of the management group. This becomes the last segment of the
    resource ID (`/providers/Microsoft.Management/managementGroups/<name>`) and
    is immutable — changing it destroys and recreates the group, which returns
    every subscription underneath it to the tenant root group.

    Only ASCII letters, digits, `-`, `_`, `(`, `)` and `.` are allowed, up to 90
    characters; spaces are not. Put the human-readable label in `display_name`.

    Null lets Azure generate a UUID, which is rarely what you want because the
    generated name is not stable across a destroy/recreate.
  EOT

  type    = string
  default = null

  validation {
    condition     = var.name == null || can(regex("^[a-zA-Z0-9_().-]{1,90}$", var.name))
    error_message = "name may only contain ASCII letters, digits, -, _, (, ), . and must be 1-90 characters. It is the resource ID segment, not the portal label — spaces and other punctuation belong in display_name."
  }
}

variable "parent_management_group_id" {
  description = <<-EOT
    Full resource ID of the parent management group, in the form
    `/providers/Microsoft.Management/managementGroups/<name>`. The provider
    rejects a bare group name. When nesting, pass the parent module's `id`
    output.

    Null places the group directly under the tenant root group.
  EOT

  type    = string
  default = null

  validation {
    condition = var.parent_management_group_id == null || can(regex(
      "^/providers/Microsoft\\.Management/managementGroups/[a-zA-Z0-9_().-]{1,90}$",
      var.parent_management_group_id
    ))
    error_message = "parent_management_group_id must be a full, case-sensitive management group resource ID such as \"/providers/Microsoft.Management/managementGroups/platform\" — a bare group name is not accepted. Use another instance of this module's `id` output."
  }
}

variable "subscription_ids" {
  description = <<-EOT
    Subscription GUIDs to associate with this management group.

    AUTHORITATIVE. On every apply the provider de-associates any subscription
    currently under the group that is missing from this set, which moves it back
    to the tenant root group — out of scope of every policy and RBAC assignment
    inherited from this group. Listing a subset therefore silently relocates the
    rest, and the provider documents an empty list as "clear all Subscriptions
    from the Management Group".

    Null (the default) leaves the attribute unset, so the module does not claim
    ownership of subscription placement at all. That is also the only safe
    setting when associations are managed with
    `azurerm_management_group_subscription_association`, which the provider
    documents as producing unpredictable results if combined with a configured
    `subscription_ids`.

    Set this only when this module is the single source of truth for which
    subscriptions live under the group, and then list every one of them.
  EOT

  type    = set(string)
  default = null

  validation {
    condition = var.subscription_ids == null || alltrue([
      for id in coalesce(var.subscription_ids, []) :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))
    ])
    error_message = "Each entry in subscription_ids must be a bare subscription GUID, not a \"/subscriptions/<guid>\" resource ID."
  }
}

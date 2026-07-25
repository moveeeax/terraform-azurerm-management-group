# terraform-azurerm-management-group

Terraform module that manages an [Azure management group](https://learn.microsoft.com/azure/governance/management-groups/overview).
It creates a single management group, optionally nested under a parent group and
associated with a set of subscriptions, exposing its ID for use in policy and
RBAC assignments.

## Usage

```hcl
module "management_group" {
  source = "github.com/moveeeax/terraform-azurerm-management-group"

  name         = "platform"
  display_name = "Platform"

  subscription_ids = [
    "00000000-0000-0000-0000-000000000000",
  ]
}
```

### Nesting

`parent_management_group_id` is a **full resource ID**, not a group name. The
`id` output of another instance of this module is exactly the right value:

```hcl
module "platform" {
  source = "github.com/moveeeax/terraform-azurerm-management-group"

  name         = "platform"
  display_name = "Platform"
}

module "workloads" {
  source = "github.com/moveeeax/terraform-azurerm-management-group"

  name                       = "platform-workloads"
  display_name               = "Platform Workloads"
  parent_management_group_id = module.platform.id
}
```

Passing a bare `"platform"` is rejected — the provider only accepts
`/providers/Microsoft.Management/managementGroups/platform`, with that exact
casing.

A runnable example lives in [`examples/basic`](examples/basic).

## `subscription_ids` is authoritative — read this before setting it

The `subscription_ids` argument on `azurerm_management_group` is an
**authoritative collection**. On every create/update the provider compares the
set you declare against the subscriptions Azure reports under the group and
de-associates everything that is not in your list. A de-associated subscription
does not stay put — it is moved back to the **tenant root group**, taking it out
of scope of every policy and RBAC assignment inherited from this group.

Practical consequences:

- **The default is `null`, meaning "unset".** The module leaves the attribute
  off the resource unless you set it, so it never claims ownership of
  subscription placement by accident. Note that this is deliberately *not* `[]`:
  the provider documents an empty list as *"To clear all Subscriptions from the
  Management Group set `subscription_ids` to an empty list"*.
- **Declare the full set, never a subset.** Once you set it, if two people
  manage the same group from different configurations, or someone attaches a
  subscription in the portal, the next `terraform apply` silently relocates
  whatever is missing from your list.
- **Prefer per-subscription resources for shared ownership.** If subscription
  placement is not owned by this module's configuration, leave
  `subscription_ids` at `null` and use
  [`azurerm_management_group_subscription_association`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_subscription_association)
  instead — it manages one association at a time and ignores the rest. The
  provider warns that combining that resource with a configured
  `subscription_ids` gives unpredictable results, so this is the only safe
  combination.
- **Use the `subscription_ids` output to spot drift.** It reflects what Azure
  reported at the last read, so comparing it with `var.subscription_ids` shows
  associations made outside Terraform that the next apply would relocate.

Two further destructive edges, both inherent to the resource:

- `name` is immutable. Changing it destroys and recreates the group, and the
  destroy first returns every child subscription to the tenant root group.
- Destroying the module does the same. Add a
  `lifecycle { prevent_destroy = true }` in your own configuration if the group
  anchors production policy.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

`azurerm >= 3.0` is the real floor: `name`, `display_name`,
`parent_management_group_id` and `subscription_ids` all exist with their current
shape and semantics from 3.0.0 onwards, and the module plans unchanged on 4.x.
The test suite additionally needs Terraform/OpenTofu >= 1.7 for `mock_provider`,
but the module itself does not.

## Inputs

| Name                         | Description                                                                                      | Type          | Default | Required |
|------------------------------|--------------------------------------------------------------------------------------------------|---------------|---------|:--------:|
| `display_name`               | Human-readable display name shown in the portal. May contain spaces.                             | `string`      | n/a     |   yes    |
| `name`                       | Name (ID) of the management group — the resource ID segment. Immutable. Null generates a UUID.    | `string`      | `null`  |    no    |
| `parent_management_group_id` | Full parent resource ID, `/providers/Microsoft.Management/managementGroups/<name>`. Null = root.  | `string`      | `null`  |    no    |
| `subscription_ids`           | Subscription GUIDs to associate. **Authoritative** — see the section above.                       | `set(string)` | `null`  |    no    |

Inputs are validated at plan time: `name` against Azure's management group name
charset (so a display-name-style value with spaces fails fast rather than in the
provider), `parent_management_group_id` against the full resource ID format, and
each `subscription_ids` entry against the GUID format (so a
`/subscriptions/<guid>` scope is rejected with a useful message).

## Outputs

| Name               | Description                                                                       |
|--------------------|-----------------------------------------------------------------------------------|
| `id`               | Full resource ID — use as a child's `parent_management_group_id` or as an RBAC scope. |
| `name`             | Name (ID) of the management group.                                                |
| `display_name`     | Display name of the management group.                                             |
| `subscription_ids` | Subscription GUIDs associated with the group as read back from Azure.             |

## Development

```sh
terraform init -backend=false
terraform validate
terraform test          # requires >= 1.7 for mock_provider; needs no credentials
tflint --init && tflint --recursive
```

## License

[MIT](LICENSE)

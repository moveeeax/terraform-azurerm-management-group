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

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                         | Description                                                          | Type          | Default | Required |
|------------------------------|----------------------------------------------------------------------|---------------|---------|:--------:|
| `display_name`               | Display name of the management group.                                | `string`      | n/a     |   yes    |
| `name`                       | Name (ID) of the management group. Null lets Azure generate a UUID.  | `string`      | `null`  |    no    |
| `parent_management_group_id` | ID of the parent management group.                                   | `string`      | `null`  |    no    |
| `subscription_ids`           | Set of subscription IDs to associate with the group.                 | `set(string)` | `[]`    |    no    |

## Outputs

| Name           | Description                              |
|----------------|------------------------------------------|
| `id`           | ID of the management group.              |
| `name`         | Name (ID) of the management group.       |
| `display_name` | Display name of the management group.    |

## License

[MIT](LICENSE)

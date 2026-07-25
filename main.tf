# `subscription_ids` is an authoritative collection: on every create/update the
# provider de-associates any subscription it finds under the group that is not
# listed here, which moves that subscription back to the tenant root group, and
# the provider documents an empty list as "clear all Subscriptions". It defaults
# to null so that the attribute is left unset and the module does not claim
# ownership of subscription placement. See the variable description and the
# README before setting it.
#
# `name` is ForceNew — changing it destroys and recreates the group, and the
# destroy returns every child subscription to the tenant root group first.
resource "azurerm_management_group" "this" {
  name                       = var.name
  display_name               = var.display_name
  parent_management_group_id = var.parent_management_group_id
  subscription_ids           = var.subscription_ids
}

output "id" {
  description = "Full resource ID of the management group (`/providers/Microsoft.Management/managementGroups/<name>`). Pass this as `parent_management_group_id` to nest another group underneath it, or use it as a scope for policy and RBAC assignments."
  value       = azurerm_management_group.this.id
}

output "name" {
  description = "Name (ID) of the management group — the last segment of `id`."
  value       = azurerm_management_group.this.name
}

output "display_name" {
  description = "Display name of the management group."
  value       = azurerm_management_group.this.display_name
}

output "subscription_ids" {
  description = "Subscription GUIDs associated with the management group as read back from Azure. Compare against `var.subscription_ids` to spot associations made outside Terraform that the next apply would move to the tenant root group."
  value       = azurerm_management_group.this.subscription_ids
}

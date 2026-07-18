output "id" {
  description = "ID of the management group."
  value       = azurerm_management_group.this.id
}

output "name" {
  description = "Name (ID) of the management group."
  value       = azurerm_management_group.this.name
}

output "display_name" {
  description = "Display name of the management group."
  value       = azurerm_management_group.this.display_name
}

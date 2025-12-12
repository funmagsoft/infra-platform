output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "private_endpoint_id" {
  description = "ID of the Private Endpoint"
  value       = azurerm_private_endpoint.this.id
}

output "private_endpoint_ip" {
  description = "Private IP address of the Private Endpoint"
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}


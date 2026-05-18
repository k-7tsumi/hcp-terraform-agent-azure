output "user_assigned_identity_id" {
  value = azurerm_user_assigned_identity.uai_langfuse_dev.id
}

output "user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.uai_langfuse_dev.client_id
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv_langfuse_dev.vault_uri
}

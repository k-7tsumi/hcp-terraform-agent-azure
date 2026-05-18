resource "azurerm_key_vault" "kv_langfuse_dev" {
  name                = "kv-langfuse-20260413"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "standard"
  tenant_id           = var.tenant_id
}

# ユーザー割り当てID
resource "azurerm_user_assigned_identity" "uai_langfuse_dev" {
  name                = "uai-langfuse"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# ユーザー割り当てIDがシークレットを取得するためのアクセスポリシー
resource "azurerm_key_vault_access_policy" "agent_vm_dev" {
  key_vault_id = azurerm_key_vault.kv_langfuse_dev.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.uai_langfuse_dev.principal_id

  secret_permissions = ["Get"]
}

# HCP Terraform SP がシークレットを管理するためのアクセスポリシー
resource "azurerm_key_vault_access_policy" "terraform_sp_dev" {
  key_vault_id = azurerm_key_vault.kv_langfuse_dev.id
  tenant_id    = var.tenant_id
  object_id    = var.hcp_terraform_sp_object_id

  secret_permissions = ["Get", "Set", "Delete", "List"]
}

# 管理者ユーザーがシークレットを参照するためのアクセスポリシー
resource "azurerm_key_vault_access_policy" "admin_user_dev" {
  key_vault_id = azurerm_key_vault.kv_langfuse_dev.id
  tenant_id    = var.tenant_id
  object_id    = var.admin_user_object_id

  secret_permissions = ["Get", "List"]
}

# HCP Terraform Agent Token
resource "azurerm_key_vault_secret" "tfc_agent_token_dev" {
  name         = "tfc-agent-token"
  value        = var.tfc_agent_token
  key_vault_id = azurerm_key_vault.kv_langfuse_dev.id
}

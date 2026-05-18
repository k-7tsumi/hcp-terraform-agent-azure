variable "location" {}

variable "resource_group_name" {}

variable "ssh_public_key" {}

variable "subnet_id" {}

variable "admin_username" {
  default = "azureuser"
}

variable "user_assigned_identity_id" {}

variable "user_assigned_identity_client_id" {}

variable "key_vault_uri" {}

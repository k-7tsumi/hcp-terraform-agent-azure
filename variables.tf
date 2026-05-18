variable "location" {
  default = "eastasia"
}

variable "resource_group_name" {
  default = "rg-agent-example"
}

variable "virtual_network_name" {
  default = "vnet-agent"
}

variable "ssh_public_key" {
  description = "SSH Public Key"
  sensitive   = true
}

variable "tenant_id" {}

variable "tfc_agent_token" {
  description = "HCP Terraform Agent Token"
  sensitive   = true
}

variable "hcp_terraform_sp_object_id" {
  description = "HCP Terraformが使用するサービスプリンシパルのObject ID"
}

variable "admin_user_object_id" {
  description = "Azure Portalでシークレットを参照する管理者ユーザーのObject ID"
}

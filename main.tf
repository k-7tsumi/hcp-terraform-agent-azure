terraform {
  required_version = ">= 1.1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.8"
    }
  }

  # HCP Terraform を使う場合はコメントアウトを外してください
  # cloud {
  #   organization = "<your-organization>"
  #   workspaces {
  #     name = "<your-workspace>"
  #   }
  # }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source               = "./modules/network"
  location             = var.location
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

module "key_vault" {
  source                     = "./modules/key_vault"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  tfc_agent_token            = var.tfc_agent_token
  hcp_terraform_sp_object_id = var.hcp_terraform_sp_object_id
  admin_user_object_id       = var.admin_user_object_id
}

module "agent" {
  source                           = "./modules/agent"
  location                         = var.location
  resource_group_name              = var.resource_group_name
  ssh_public_key                   = var.ssh_public_key
  virtual_network_name             = module.network.virtual_network_name
  user_assigned_identity_id        = module.key_vault.user_assigned_identity_id
  user_assigned_identity_client_id = module.key_vault.user_assigned_identity_client_id
  key_vault_uri                    = module.key_vault.key_vault_uri
}

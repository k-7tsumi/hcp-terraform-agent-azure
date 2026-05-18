module "network" {
  source               = "./network"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

module "virtual_machine" {
  source              = "./virtual_machine"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id                        = module.network.subnet_id
  ssh_public_key                   = var.ssh_public_key
  user_assigned_identity_id        = var.user_assigned_identity_id
  user_assigned_identity_client_id = var.user_assigned_identity_client_id
  key_vault_uri                    = var.key_vault_uri
}

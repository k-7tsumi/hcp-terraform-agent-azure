# 仮想ネットワーク
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.1.0/24", "10.0.2.0/24"]
  location            = var.location
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

# Bastionサブネット
resource "azurerm_subnet" "bastion_subnet" {
  address_prefixes     = ["10.0.2.0/26"]
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}

# BastionパブリックIP
resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "public-ip-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Bastionホスト
resource "azurerm_bastion_host" "bastion_host" {
  name                = "bastion-host"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

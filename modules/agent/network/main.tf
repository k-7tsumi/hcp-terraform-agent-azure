# Agentサブネット
resource "azurerm_subnet" "subnet_agent" {
  address_prefixes     = ["10.0.2.64/28"]
  name                 = "subnet-agent"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

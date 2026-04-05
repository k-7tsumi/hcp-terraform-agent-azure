# ネットワークインターフェース
resource "azurerm_network_interface" "nic_agent" {
  location            = var.location
  name                = "nic-agent"
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig-agent"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# 仮想マシン
resource "azurerm_linux_virtual_machine" "vm_agent" {
  location              = var.location
  name                  = "vm-agent"
  resource_group_name   = var.resource_group_name
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic_agent.id]
  size                  = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # Ubuntu 22.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

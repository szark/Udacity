variable "vm_base_name" {
  description = "Base name for the virtual machines"
  default     = "UbuntuVM"
}

variable "vm_count" {
  description = "Number of virtual machines to deploy"
  default     = 5
}

resource "azurerm_virtual_machine" "vm" {
  count                  = var.vm_count
  name                   = "${var.vm_base_name}${count.index}"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  network_interface_ids  = [azurerm_network_interface.nic[count.index].id]
  vm_size                = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.vm_base_name}${count.index}_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = 30
  }

  os_profile {
    computer_name  = "${var.vm_base_name}${count.index}"
    admin_username = "azureuser"
    admin_password = "Pa$$w0rd1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface" "nic" {
  count                = var.vm_count
  name                 = "${var.vm_base_name}${count.index}NIC"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "Vmdeploy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "default"
    address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "example-rg"
  location = "West Europe"
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
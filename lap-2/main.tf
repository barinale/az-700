terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.35.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


resource "azurerm_resource_group" "rs-G-az700dns" {
  name     = "rs-G-az700dns"
  location = "West Europe"
   tags = {
    type = "az700"
  }
}


resource "azurerm_virtual_network" "vrn-1" {
  name                = "vrn-1"
  location            = azurerm_resource_group.rs-G-az700dns.location
  resource_group_name = azurerm_resource_group.rs-G-az700dns.name
  address_space       = ["10.0.0.0/16"]


  subnet {
    name             = "subnet1"
    address_prefixes = ["10.0.1.0/24"]
  }

  subnet {
    name             = "subnet2"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = azurerm_network_security_group.network-securty-2.id
  }

  tags = {
    type = "az700"
  }
}
data "azurerm_subnet" "my_subnet" {
  name                 = "subnet1"
  virtual_network_name = azurerm_virtual_network.vrn-1.name
  resource_group_name  = azurerm_resource_group.rs-G-az700dns.name
}

data "azurerm_subnet" "my_subnet2" {
  name                 = "subnet2"
  virtual_network_name = azurerm_virtual_network.vrn-1.name
  resource_group_name  = azurerm_resource_group.rs-G-az700dns.name
}


resource "azurerm_network_interface" "intf-1" {
  name                = "intf-1"
  location            = azurerm_resource_group.rs-G-az700dns.location
  resource_group_name = azurerm_resource_group.rs-G-az700dns.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
   tags = {
    type = "az700"
  }
}

resource "azurerm_linux_virtual_machine" "vm-linux" {
  name                = "vm-linux"
  resource_group_name = azurerm_resource_group.rs-G-az700dns.name
  location            = azurerm_resource_group.rs-G-az700dns.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password        = var.admin_password
  disable_password_authentication = false  
  network_interface_ids = [
    azurerm_network_interface.intf-1.id,
  ]

  

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


resource "azurerm_network_interface" "intf-2" {
  name                = "intf-2"
  location            = azurerm_resource_group.rs-G-az700dns.location
  resource_group_name = azurerm_resource_group.rs-G-az700dns.name
   ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.my_subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip2.id
  }


   tags = {
    type = "az700"
  }
}

resource "azurerm_linux_virtual_machine" "vm-linux2" {
  name                = "vm-linux2"
  resource_group_name = azurerm_resource_group.rs-G-az700dns.name
  location            = azurerm_resource_group.rs-G-az700dns.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password        = var.admin_password
  disable_password_authentication = false  
  network_interface_ids = [
    azurerm_network_interface.intf-2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "public-ip2" {
  name                = "public-ip2"
  resource_group_name = azurerm_resource_group.rs-G-az700dns.name
  location            = azurerm_resource_group.rs-G-az700dns.location
  allocation_method   = "Static"

  tags = {
    typz = "az700"
  }
}


resource "azurerm_network_security_group" "network-securty-2" {
  name                = "network-securty-2"
  location            = azurerm_resource_group.rs-G-az700dns.location
  resource_group_name = azurerm_resource_group.rs-G-az700dns.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
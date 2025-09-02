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

resource "azurerm_resource_group" "rsg-1" {
  name     = "ContosoResourceGroup"
  location = "East us"
}



resource "azurerm_virtual_network" "vn-1" {
  name                = "CoreServicesVnet"
  location            = azurerm_resource_group.rsg-1.location
  resource_group_name = azurerm_resource_group.rsg-1.name
  address_space       = ["10.20.0.0/16"]


  subnet {
    name             = "subnet1"
    address_prefixes = ["10.20.20.0/24"]
  }
  subnet {
    name             = "GatewaySubnet"
    address_prefixes = ["10.20.0.0/27"]
  }
  tags = {
    learn = "vnGatewaye"
  }
}

resource "azurerm_virtual_network" "vn-2" {
  name                = "ManufacturingVnet"
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rsg-1.name
  address_space       = ["10.30.0.0/16"]


  subnet {
    name             = "subnet1"
    address_prefixes = ["10.30.10.0/24"]
    security_group   = azurerm_network_security_group.network-securty-2.id
  }
 subnet {
    name             = "GatewaySubnet"
    address_prefixes = ["10.30.0.0/27"]
  }


  tags = {
    learn = "vnGatewaye"
  }
}

data "azurerm_subnet" "vn1-s1" {
  name                 = "subnet1"
  virtual_network_name = azurerm_virtual_network.vn-1.name
  resource_group_name  = azurerm_resource_group.rsg-1.name
}

data "azurerm_subnet" "vn1-s2" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vn-1.name
  resource_group_name  = azurerm_resource_group.rsg-1.name
}

data "azurerm_subnet" "vn2-s1" {
  name                 = "subnet1"
  virtual_network_name = azurerm_virtual_network.vn-2.name
  resource_group_name  = azurerm_resource_group.rsg-1.name
}

data "azurerm_subnet" "vn2-s2" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vn-2.name
  resource_group_name  = azurerm_resource_group.rsg-1.name
}


resource "azurerm_network_interface" "vm1-int" {
  name                = "interface-1"
  location            = azurerm_resource_group.rsg-1.location
  resource_group_name = azurerm_resource_group.rsg-1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.vn1-s1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "CoreServicesVM"
  resource_group_name = azurerm_resource_group.rsg-1.name
  location            = azurerm_resource_group.rsg-1.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm1-int.id,
  ]

  admin_password        = var.admin_password
  disable_password_authentication = false  

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

resource "azurerm_network_interface" "vm2-int2" {
  name                = "interface-2"
  location            = azurerm_virtual_network.vn-2.location
  resource_group_name = azurerm_resource_group.rsg-1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.vn2-s1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip2.id

  }

}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "ManufacturingVM"
  resource_group_name = azurerm_resource_group.rsg-1.name
  location            = azurerm_virtual_network.vn-2.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm2-int2.id,
  ]

  admin_password        = var.admin_password
  disable_password_authentication = false  

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

resource "azurerm_network_security_group" "network-securty-2" {
  name                = "network-securty-2"
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.rsg-1.name

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

}

resource "azurerm_public_ip" "public-ip2" {
  name                = "public-ip2"
  resource_group_name = azurerm_resource_group.rsg-1.name 
  location            = azurerm_virtual_network.vn-2.location
  allocation_method   = "Static"
}
//gateway for vn2
resource "azurerm_public_ip" "vng_ip2" {
  name                = "vng-public-ip2"
  location            = azurerm_virtual_network.vn-2.location
  resource_group_name = azurerm_resource_group.rsg-1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5. Virtual Network Gateway
resource "azurerm_virtual_network_gateway" "vng2" {
  name                = "ManufacturingVnetGateway"
  location            = azurerm_virtual_network.vn-2.location
  resource_group_name = azurerm_resource_group.rsg-1.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "vng-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vng_ip2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.vn2-s2.id
  }
}
//gatewayfor vn1
resource "azurerm_public_ip" "vng_ip1" {
  name                = "vng-public-ip1"
  location            = azurerm_virtual_network.vn-1.location
  resource_group_name = azurerm_resource_group.rsg-1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5. Virtual Network Gateway
resource "azurerm_virtual_network_gateway" "vng1" {
  name                = "CoreServicesVnet"
  location            = azurerm_virtual_network.vn-1.location
  resource_group_name = azurerm_resource_group.rsg-1.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "vng-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vng_ip1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.vn1-s2.id
  }
}



// for connection between vnt


resource "azurerm_virtual_network_gateway_connection" "us_to_europe" {
  name                = "vn1-to-vn2"
  location            = azurerm_resource_group.rsg-1.location
  resource_group_name = azurerm_resource_group.rsg-1.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vng1.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng2.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

resource "azurerm_virtual_network_gateway_connection" "europe_to_us" {
  name                = "vn2-to-vn1"
  location            = azurerm_linux_virtual_machine.vm2.location
  resource_group_name = azurerm_resource_group.rsg-1.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vng2.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng1.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}
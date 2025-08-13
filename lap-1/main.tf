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

resource "azurerm_resource_group" "RG-east-US" {
  name     = "RG-eastus-az700"
  location = "East US"
}

# resource "azurerm_network_security_group" "RG-east-NS" {
#   name                = "network-securty-group-eastus"
#   location            = azurerm_resource_group.RG-east-US.location
#   resource_group_name = azurerm_resource_group.RG-east-US.name
# }

resource "azurerm_virtual_network" "CoreServicesVnet" {
  name                = "CoreServicesVnet"
  location            = azurerm_resource_group.RG-east-US.location
  resource_group_name = azurerm_resource_group.RG-east-US.name
  address_space       = ["10.20.0.0/16"]
  # dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "GatewaySubnet"
    address_prefixes = ["10.20.0.0/27"]
  }

  subnet {
    name             = "SharedServicesSubnet"
    address_prefixes = ["10.20.10.0/24"]
    # security_group   = azurerm_network_security_group.example.id
  }
  subnet {
    name             = "DatabaseSubnet"
    address_prefixes = ["10.20.20.0/24"]
    # security_group   = azurerm_network_security_group.example.id
  }
  subnet {
      name             = "PublicWebServiceSubnet"
      address_prefixes = ["10.20.30.0/24"]
      # security_group   = azurerm_network_security_group.example.id
    }
  tags = {
    type = "learningaz700"
  }
}


resource "azurerm_resource_group" "RG-West-Europe" {
  name     = "RG-eastus"
  location = "West Europe"
}

resource "azurerm_virtual_network" "ManufacturingVnet" {
  name                = "ManufacturingVnet"
  location            = azurerm_resource_group.RG-West-Europe.location
  resource_group_name = azurerm_resource_group.RG-West-Europe.name
  address_space       = ["10.30.0.0/16"]
  # dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "ManufacturingSystemSubnet"
    address_prefixes = ["10.30.10.0/24"]
  }

  subnet {
    name             = "SensorSubnet1"
    address_prefixes = ["10.30.20.0/24"]
    # security_group   = azurerm_network_security_group.example.id
  }
  subnet {
    name             = "SensorSubnet2"
    address_prefixes = ["10.30.21.0/24"]
    # security_group   = azurerm_network_security_group.example.id
  }
  subnet {
      name             = "SensorSubnet3"
      address_prefixes = ["10.30.22.0/24"]
      # security_group   = azurerm_network_security_group.example.id
    }
  tags = {
    type = "learningaz700"
  }
}

resource "azurerm_resource_group" "RG-Southeast" {
  name     = "ResearchVnet"
  location = "West Europe"
}

resource "azurerm_virtual_network" "ResearchVnet" {
  name                = "ManufacturingVnet"
  location            = azurerm_resource_group.RG-Southeast.location
  resource_group_name = azurerm_resource_group.RG-Southeast.name
  address_space       = ["10.40.0.0/16"]
  
 subnet {
      name             = "ResearchSystemSubnet"
      address_prefixes = ["10.40.0.0/24"]
    }

  tags = {
    type = "learningaz700"
  }
}

# Configure the Terraform runtime requirements.
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    # Azure Resource Manager provider and version
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
  }
}

# Define providers and their config params
provider "azurerm" {
  # Leave the features block empty to accept all defaults
  features {}
}

provider "cloudinit" {
  # Configuration options
}

variable "labelPrefix" {
  description = "A prefix for all resource names, typically your college username"
  type        = string
}

variable "region" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "canadacentral"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.labelPrefix}-A05-RG"
  location = var.region
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.labelPrefix}-A05-PubIP"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Standard"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.labelPrefix}-A05-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.labelPrefix}-A05-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_network_security_group" "nsg" {
  name                = "${var.labelPrefix}-A05-NSG"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.labelPrefix}-A05-NIC"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

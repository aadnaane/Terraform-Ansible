terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.1"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate3iews"
    container_name       = "tfstate"
    key                  = "networking.terraform.tfstate"
}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "pwc_rg" {
  name     = "PWC-PRODUCTION"
  location = "East Asia"
  tags = {
    creator    = "ACHAHBAR"
    maintainer = "DevOps Team"
    manager    = "Hinde"
  }
}

resource "azurerm_virtual_network" "myvnet" {
  name                = "My-virtual-network"
  location            = azurerm_resource_group.pwc_rg.location
  resource_group_name = azurerm_resource_group.pwc_rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "Staging"
  }

}

resource "azurerm_subnet" "asn_1" {
  name                 = "subnet-1"
  resource_group_name  = azurerm_resource_group.pwc_rg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_network_security_group" "nsg" {
  name                = "postgres-card-network-security-group"
  location            = azurerm_resource_group.pwc_rg.location
  resource_group_name = azurerm_resource_group.pwc_rg.name

  security_rule {
    name                       = "SSH"
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
    name                       = "Postgresql"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "public_ip_postgres" {
  name                = "postgres_pub_ip"
  resource_group_name = azurerm_resource_group.pwc_rg.name
  location            = azurerm_resource_group.pwc_rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "MyVM-nic"
  location            = azurerm_resource_group.pwc_rg.location
  resource_group_name = azurerm_resource_group.pwc_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.asn_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_postgres.id
  }
}

resource "azurerm_network_interface_security_group_association" "postgresAssociation" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "tls_private_key" "postgres_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
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
    key                  = "terraform.tfstate"
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

resource "azurerm_linux_virtual_machine" "MyVM" {
  name                = "PostgreSQL-Server"
  resource_group_name = azurerm_resource_group.pwc_rg.name
  location            = azurerm_resource_group.pwc_rg.location
  size                = "Standard_B2s"
  admin_username      = "kali"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "kali"
    public_key = tls_private_key.postgres_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = "terraform output -raw postgres_ssh > postgres.pem"
  }

  provisioner "local-exec" {
    command = "chmod 400 *pem"
  }


  provisioner "local-exec" {
    working_dir = "/usr/local/bin/Projects/Ansible-thingies"
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --inventory ${self.public_ip_address}, --private-key /usr/local/bin/Projects/Terraform-azure/postgres.pem --user kali postgres-playbook.yaml"

  }
}

resource "azurerm_linux_virtual_machine" "MyVM" {
  name                = "PostgreSQL-Server"
  resource_group_name = azurerm_resource_group.pwc_rg.name
  location            = azurerm_resource_group.pwc_rg.location
  size                = "Standard_B2s"
  admin_username      = "kali"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "kali"
    public_key = tls_private_key.postgres_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = "terraform output -raw postgres_ssh > postgres.pem"
  }

  provisioner "local-exec" {
    command = "chmod 400 *pem"
  }


  provisioner "local-exec" {
    working_dir = "/usr/local/bin/Projects/Ansible-thingies"
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --inventory ${self.public_ip_address}, --private-key /usr/local/bin/Projects/Terraform-azure/postgres.pem --user kali postgres-playbook.yaml"

  }
}


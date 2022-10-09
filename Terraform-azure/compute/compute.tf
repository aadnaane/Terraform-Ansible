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
    key                  = "compute.terraform.tfstate"
}
}

provider "azurerm" {
  features {}
}

data "terraform_remote_state" "networking_state" {
  backend = "azurerm"
  config = {
    storage_account_name = "tfstate3iews"
    container_name       = "tfstate"
    key                  = "networking.terraform.tfstate"
  }
}


resource "azurerm_linux_virtual_machine" "MyVM" {
  name                = "PostgreSQL-Server"
  resource_group_name = azurerm_resource_group.data.terraform_remote_state.networking_state..pwc_rg.name
  location            = azurerm_resource_group.pwc_rg.location
  size                = "Standard_B2s"
  admin_username      = "kali"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "kalo"
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


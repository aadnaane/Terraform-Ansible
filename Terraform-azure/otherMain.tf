terraform {
}


resource "azurerm_resource_group" "pwc_rg_2" {
  name     = "PWC-DEV"
  location = "East Asia"
  tags = {
    creator    = "ACHAHBAR for DEV"
    maintainer = "DevOps Team"
    manager    = "Hinde"
  }
}
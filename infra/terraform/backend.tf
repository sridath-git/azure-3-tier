terraform {
  backend "azurerm" {
    resource_group_name  = "azure-3-tier-3tier-tfstate-rg"
    storage_account_name = "azure-3-tiertfstate316954570"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

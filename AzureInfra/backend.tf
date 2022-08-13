terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.17.0"
    }
  }

backend "azurerm" {
    resource_group_name  = "tstate-rg"
    storage_account_name = "tfstr8811"
    container_name       = "tfstate"
    key                 = "mediawiki_b.tfstate"
    access_key           = var.storageaccess_key

  }
}
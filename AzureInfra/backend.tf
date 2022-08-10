terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.4.6"
    }
  }

backend "azurerm" {
    resource_group_name  = "tstate-rg"
    storage_account_name = "tfstr8811"
    container_name       = "tfstate"
    key                 = "mediawiki_b.tfstate"
    access_key           = "W0q2+9GdV0Dh9Hjy3uGIK49RWnhYy9D3/kpvEtPD+ENt9ghTQqWz07zwDyXKy4HGkc+D1EYH3iAk+AStfV6zGw=="

  }
}
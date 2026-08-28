terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

 backend "azurerm" {
  resource_group_name = "52logistics-rg"
  storage_account_name = "st52logisticstfstate"
  container_name = "tfstate"
  key = "governance.tfstate"
 }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
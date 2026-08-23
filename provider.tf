## Configures the Terraform provider for Azure Resource Manager (azurerm) and specifies the required provider version. The provider block includes the subscription ID variable, which is used to authenticate and manage resources within the specified Azure subscription. The features block is included to enable any necessary features for the azurerm provider, ensuring compatibility with the resources being managed in this Terraform configuration.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
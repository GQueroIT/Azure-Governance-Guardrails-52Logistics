## Creates an Azure resource group using the specified name and location variables. The resource group serves as a container for related Azure resources, allowing for better organization and management of resources within the Azure subscription. The resource group name and location are defined as variables in the variables.tf file, enabling easy customization and reuse of this Terraform configuration across different environments or projects.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location

}
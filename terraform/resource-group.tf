resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
    Environment = "Production"
  }
}

resource "azurerm_resource_group" "monitoring_rg" {
  name     = var.resource_group_name_monitor
  location = var.resource_group_location
  tags = {
    Environment = "Production"
    Pipeline = "test"
  }
}
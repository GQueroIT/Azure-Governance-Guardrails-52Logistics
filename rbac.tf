resource "azurerm_role_assignment" "rg_contributor" {

  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = var.principal_id
}

data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "subscription_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = var.principal_id
}
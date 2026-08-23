resource "azurerm_management_lock" "rg_delete-lock" {

  scope      = azurerm_resource_group.rg.id
  name       = "rg-delete-lock"
  lock_level = "CanNotDelete"
}
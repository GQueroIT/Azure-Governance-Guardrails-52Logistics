resource "azurerm_management_lock" "rg_delete_lock" {

  scope      = azurerm_resource_group.rg.id
  name       = "rg_delete_lock"
  lock_level = "CanNotDelete"
}

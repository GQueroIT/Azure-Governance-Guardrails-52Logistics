## Creates a management lock at the resource group level to prevent accidental deletion of the resource group and its associated resources.
## The lock is configured with the "CanNotDelete" level, which allows users to read and modify resources within the resource group but prevents them from deleting the resource group itself.
## This lock provides an additional layer of protection for critical resources, ensuring that they cannot be removed without first removing the lock.

resource "azurerm_management_lock" "rg_delete_lock" {

  scope      = azurerm_resource_group.rg.id
  name       = "rg_delete_lock"
  lock_level = "CanNotDelete"
}

## Assigns the "Contributor" role to a specified principal (user, group, or service principal) at the resource group level.
## This allows the principal to manage resources within the resource group, including creating, updating, and deleting resources.
## The role assignment is scoped to the resource group created earlier in the configuration.
## The principal ID is provided as a variable, enabling flexibility in assigning roles to different users or service principals as needed.
## This role assignment is essential for granting the necessary permissions to manage resources within the defined resource group.

resource "azurerm_role_assignment" "rg_contributor" {

  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = var.testuser_principal_id
}

data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "subscription_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = var.testuser_principal_id
}
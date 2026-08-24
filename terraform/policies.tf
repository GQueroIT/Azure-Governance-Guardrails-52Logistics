data "azurerm_policy_definition" "required_tag" {
  display_name = "Require a tag and its value on resources"
}

resource "azurerm_subscription_policy_assignment" "required_tag" {
  name                 = "required-tag"
  policy_definition_id = data.azurerm_policy_definition.required_tag.id
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    tagName = {
      value = "Environment"
    }
    tagValue = {
      value = "Production"
    }
  })
}

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  subscription_id      = data.azurerm_subscription.current.id

  not_scopes = [
    azurerm_resource_group.monitoring_rg.id
  ]

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["eastus",
      "eastus2"]
    }
  })
}

data "azurerm_policy_definition" "allowed_virtual_machine_size_SKUs" {
  display_name = "Allowed virtual machine size SKUs"
}

resource "azurerm_subscription_policy_assignment" "allowed_virtual_machine_size_SKUs" {
  name                 = "Allowed virtual machine size SKUs"
  policy_definition_id = data.azurerm_policy_definition.allowed_virtual_machine_size_SKUs.id
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    listOfAllowedSKUs = {
      value = ["Standard_B1s",
      "Standard_B2s"]
    }
  })
}


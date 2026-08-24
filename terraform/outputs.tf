output "resource_group_id" {
  description = "The ID of the governance resource group"
  value       = azurerm_resource_group.rg.id
}

output "resource_group_name" {
  description = "The name of the governance resource group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_monitor_id" {
  description = "The ID of the monitoring resource group"
  value       = azurerm_resource_group.monitoring_rg.id
}

output "resource_group_name_monitor" {
  description = "The name of the monitoring resource group"
  value       = azurerm_resource_group.monitoring_rg.name
}

output "require_tag_policy_id" {
  description = "The ID of the required tag policy assignment"
  value       = azurerm_subscription_policy_assignment.required_tag.id
}

output "require_tag_policy_name" {
  description = "The name of the required tag policy assignment"
  value       = azurerm_subscription_policy_assignment.required_tag.name
}

output "allowed_locations_policy_id" {
  description = "The ID of the allowed locations policy assignment"
  value       = azurerm_subscription_policy_assignment.allowed_locations.id
}

output "allowed_locations_policy_name" {
  description = "The name of the allowed locations policy assignment"
  value       = azurerm_subscription_policy_assignment.allowed_locations.name
}

output "resource_group_lock_id" {
  description = "The ID of the CanNotDelete management lock applied to the governance resource group"
  value       = azurerm_management_lock.rg_delete_lock.id
}

output "resource_group_lock_name" {
  description = "The name of the CanNotDelete management lock applied to the governance resource group"
  value       = azurerm_management_lock.rg_delete_lock.name
}

output "allowed_vm_skus_policy_id" {
  description = "The ID of the allowed VM sizes policy assignment"
  value       = azurerm_subscription_policy_assignment.allowed_virtual_machine_size_SKUs.id
}

output "allowed_vm_skus_policy_name" {
  description = "The name of the allowed VM sizes policy assignment"
  value       = azurerm_subscription_policy_assignment.allowed_virtual_machine_size_SKUs.name
}

output "rg_contributor_role_assignment_id" {
  description = "The ID of the Contributor role assignment at resource group scope"
  value       = azurerm_role_assignment.rg_contributor.id
}

output "rg_contributor_role_assignment_name" {
  description = "The name of the Contributor role assignment at resource group scope"
  value       = azurerm_role_assignment.rg_contributor.name
}

output "subscription_reader_role_assignment_id" {
  description = "The ID of the Reader role assignment at subscription scope"
  value       = azurerm_role_assignment.subscription_reader.id
}

output "subscription_reader_role_assignment_name" {
  description = "The name of the Reader role assignment at subscription scope"
  value       = azurerm_role_assignment.subscription_reader.name
}

output "defender_cloud_posture_id" {
  description = "The ID of the Defender for Cloud posture pricing configuration"
  value       = azurerm_security_center_subscription_pricing.cloud_posture.id
}

output "defender_cloud_posture_tier" {
  description = "The Defender for Cloud posture pricing tier"
  value       = azurerm_security_center_subscription_pricing.cloud_posture.tier
}

output "consumption_budget_subscription_id" {
  description = "The ID of the monthly budget consumption"
  value       = azurerm_consumption_budget_subscription.monthly_budget.id
}

output "consumption_budget_subscription_name" {
  description = "The name of the monthly budget consumption"
  value       = azurerm_consumption_budget_subscription.monthly_budget.name
}

output "azurerm_monitor_action_group_id" {
  description = "Monitor action group ID"
  value       = azurerm_monitor_action_group.governance_alerts.id
}

output "azurerm_monitor_action_group_name" {
  description = "The name of the action group created for monitoring"
  value       = azurerm_monitor_action_group.governance_alerts.name
}
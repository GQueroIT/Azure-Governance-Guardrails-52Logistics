## Adds variables for the Azure subscription ID, resource group name, resource group location, and principal ID.
## These variables are used in the provider configuration, resource group creation, and role assignment resources.
## Moreover, the subscription ID and principal ID are marked as sensitive to ensure that they are not displayed in logs or output.
## As the project grows in scope, additional variables can be added to this file to manage other aspects of the Azure environment, such as virtual networks, storage accounts, or other resources.
## This modular approach allows for better organization and maintainability of the Terraform codebase.

variable "subscription_id" {
  description = "Azure subscription ID used for the 52 Logistics governance environment"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "The name of the resource group to create"
  type        = string
}

variable "resource_group_name_monitor" {
  description = "The name of the monitoring resource group"
  type        = string
}


variable "resource_group_location" {
  description = "The location of the resource group to create"
  type        = string
}

variable "principal_id" {
  description = "The principal ID of the user or service principal to assign the role to"
  type        = string
  sensitive   = true
}

variable "testuser_principal_id" {
  description = "The principal ID of the test user or service principal to assign the role to"
  type        = string
  sensitive   = true
}

variable "budget_notification_email" {
  description = "Email address used for Azure budget notifications"
  type        = string
}

variable "governance_alert_email" {
  description = "Email address used for governance and security alerts"
  type        = string
  sensitive   = true
}
variable "subscription_id" {
  description = "Azure subscription ID used for the 52 Logistics governance environment"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "The name of the resource group to create"
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
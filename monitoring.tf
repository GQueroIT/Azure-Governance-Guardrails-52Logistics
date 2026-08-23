resource "azurerm_monitor_action_group" "governance_alerts" {
  name                = "52logistics-governance-alerts"
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  short_name          = "gov-alerts"
  tags = {
    Environment = "Production"
  }
  email_receiver {
    name          = "GovernanceAdmin"
    email_address = var.governance_alert_email
  }
}

resource "azurerm_monitor_activity_log_alert" "management_lock_deleted" {
  name                = "52logistics-management_lock_deleted"
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  location            = "global"

  scopes = [
    data.azurerm_subscription.current.id
  ]

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Authorization/locks/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.governance_alerts.id
  }

  tags = {
    Environment = "Production"
  }
}
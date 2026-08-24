resource "azurerm_consumption_budget_subscription" "monthly_budget" {
  name            = "monthly_budget"
  subscription_id = data.azurerm_subscription.current.id
  amount          = 50
  time_grain      = "Monthly"
  time_period {
    start_date = "2026-08-01T00:00:00Z"
  }
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_notification_email]
  }
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_notification_email]
  }
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_notification_email]
  }
}
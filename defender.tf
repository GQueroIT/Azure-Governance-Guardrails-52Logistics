resource "azurerm_security_center_subscription_pricing" "cloud_posture" {
  tier          = "Free"
  resource_type = "CloudPosture"
}
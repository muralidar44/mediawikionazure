 provider "azurerm" {
   features {}

  subscription_id = "49db0cbb-ac2c-4caa-b82b-39b1426c634d"
  client_id       = "7e661f12-b6ab-443a-a439-098b2700ae2f"
  client_secret   = var.client_secret
  tenant_id       = "c7e8dde8-5811-4ad2-bc91-f0e957a0ca3e"

 }
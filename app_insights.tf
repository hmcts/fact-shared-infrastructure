# This is the application insights used for the new FaCT
module "app_insights" {
  source = "git@github.com:hmcts/terraform-module-application-insights?ref=4.x"

  env      = var.env
  product  = var.product
  name     = "${var.product}-ai"
  location = var.appinsights_ai_location

  resource_group_name = azurerm_resource_group.rg.name
  common_tags         = var.common_tags
}

resource "azurerm_key_vault_secret" "app_insights_connection_string_ai" {
  name         = "app-insights-connection-string"
  value        = module.app_insights.connection_string
  key_vault_id = module.key_vault.key_vault_id
}


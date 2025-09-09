module "application_insights_new" {
  source = "git@github.com:hmcts/terraform-module-application-insights?ref=4.x"

  env      = var.env
  product  = var.product
  name     = "${var.product}-appinsights-ai"
  location = var.appinsights_ai_location

  resource_group_name = azurerm_resource_group.rg.name
  common_tags         = var.common_tags
}

resource "azurerm_key_vault_secret" "AZURE_APPINSIGHTS_KEY_AI" {
  name         = "AppInsightsInstrumentationKey-ai"
  value        = module.application_insights_new.instrumentation_key
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "app_insights_connection_string_ai" {
  name         = "app-insights-connection-string-ai"
  value        = module.application_insights_new.connection_string
  key_vault_id = module.key-vault.key_vault_id
}

output "app_insights_ai_instrumentation_key" {
  value = module.application_insights_new.instrumentation_key
}

output "app_insights_ai_connection_string" {
  value = module.application_insights_new.connection_string
}

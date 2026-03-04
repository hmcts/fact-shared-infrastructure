# These are the calculated secrets used by the new FaCT
locals {
  app_reg_suffix           = var.env == "prod" ? "prod" : "non-prod"
  api_app_reg_name         = "fact-data-api-${local.app_reg_suffix}"
  test_client_app_reg_name = "fact-admin-frontend-${local.app_reg_suffix}"
  public_frontend_app_reg_name = "fact-frontend-${local.app_reg_suffix}"
}

resource "random_password" "session_string" {
  length      = 20
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
  special     = true
}

data "azuread_application" "api_app_reg" {
  display_name = local.api_app_reg_name
}

data "azuread_application" "test_client_app_reg" {
  display_name = local.test_client_app_reg_name
}

data "azuread_application" "public_frontend_app_reg" {
  display_name = local.public_frontend_app_reg_name
}

resource "azurerm_key_vault_secret" "api_app_reg_id" {
  name         = "api-app-reg-id"
  value        = data.azuread_application.api_app_reg.client_id
  key_vault_id = module.key_vault.key_vault_id
  tags = merge(var.common_tags, {
    "source" : "calculated from ${local.api_app_reg_name} app reg"
  })
  content_type    = "Calculated Secret"
  expiration_date = timeadd(timestamp(), "17520h")
}

resource "azurerm_key_vault_secret" "public_frontend_app_reg_id" {
  name         = " public-frontend-app-reg-id"
  value        = data.azuread_application.public_frontend_app_reg.client_id
  key_vault_id = module.key_vault.key_vault_id
  tags = merge(var.common_tags, {
    "source" : "calculated from ${local.api_app_reg_name} app reg"
  })
  content_type    = "Calculated Secret"
  expiration_date = timeadd(timestamp(), "17520h")
}

resource "azurerm_key_vault_secret" "test_client_app_reg_id" {
  count        = var.env == "aat" ? 1 : 0
  name         = "func-test-client-app-id"
  value        = data.azuread_application.test_client_app_reg.client_id
  key_vault_id = module.key_vault.key_vault_id
  tags = merge(var.common_tags, {
    "source" : "calculated from ${local.test_client_app_reg_name} app reg"
  })
  content_type    = "Calculated Secret"
  expiration_date = timeadd(timestamp(), "17520h")
}

resource "azurerm_key_vault_secret" "test_client_viewer_app_reg_id" {
  count        = var.env == "aat" ? 1 : 0
  name         = "func-test-viewer-client-app-id"
  value        = data.azuread_application.public_frontend_app_reg.client_id
  key_vault_id = module.key_vault.key_vault_id
  tags = merge(var.common_tags, {
    "source" : "calculated from ${local.test_viewer_app_reg_name} app reg"
  })
  content_type    = "Calculated Secret"
  expiration_date = timeadd(timestamp(), "17520h")
}

resource "azurerm_key_vault_secret" "test_client_tenant_id" {
  count           = var.env == "aat" ? 1 : 0
  name            = "func-test-tenant-id"
  value           = var.tenant_id
  key_vault_id    = module.key_vault.key_vault_id
  tags            = var.common_tags
  content_type    = "Calculated Secret"
  expiration_date = timeadd(timestamp(), "17520h")
}

resource "azurerm_key_vault_secret" "session_secret" {
  name            = "session-secret"
  value           = random_password.session_string.result
  key_vault_id    = module.key_vault.key_vault_id
  tags            = var.common_tags
  content_type    = "Calculated Secret"
  expiration_date = timeadd(timestamp(), "17520h")
}

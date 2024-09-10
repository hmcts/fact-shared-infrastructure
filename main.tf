provider "azurerm" {
  features {}
}

locals {
  images = [
  ]
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.product}-${var.env}"
  location = var.location

  tags = var.common_tags
}

module "key-vault" {
  source              = "git@github.com:hmcts/cnp-module-key-vault?ref=master"
  product             = var.product
  env                 = var.env
  tenant_id           = var.tenant_id
  object_id           = var.jenkins_AAD_objectId
  resource_group_name = azurerm_resource_group.rg.name

  # dcd_platformengineering group object ID
  product_group_name      = "DTS FaCT"
  common_tags             = var.common_tags
  create_managed_identity = true
}

resource "azurerm_key_vault_secret" "AZURE_APPINSIGHTS_KEY" {
  name         = "AppInsightsInstrumentationKey"
  value        = module.application_insights.instrumentation_key
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "app-insights-connection-string"
  value        = module.application_insights.connection_string
  key_vault_id = module.key-vault.key_vault_id
}

module "application_insights" {
  source = "git@github.com:hmcts/terraform-module-application-insights?ref=main"

  env      = var.env
  product  = var.product
  name     = "${var.product}-appinsights"
  location = var.location

  resource_group_name = azurerm_resource_group.rg.name

  common_tags = var.common_tags
}

moved {
  from = azurerm_application_insights.appinsights
  to   = module.application_insights.azurerm_application_insights.this
}

resource "azurerm_storage_account" "storage_account" {
  name                = replace("${var.product}${var.env}", "-", "")
  resource_group_name = azurerm_resource_group.rg.name

  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  account_kind                    = "StorageV2"
  allow_nested_items_to_be_public = true

  tags = var.common_tags
}

resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "container"
}

resource "azurerm_storage_blob" "images" {
  name                   = local.images[count.index]
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.images.name
  type                   = "Block"
  source_uri             = "https://8d96a24990d0prodcf.blob.core.windows.net/media/images/${local.images[count.index]}"
  count                  = length(local.images)
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.storage_account.name
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "storage_account_primary_key" {
  name         = "storage-account-primary-key"
  value        = azurerm_storage_account.storage_account.primary_access_key
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "storage_account_connection_string" {
  name         = "storage-account-connection-string"
  value        = azurerm_storage_account.storage_account.primary_connection_string
  key_vault_id = module.key-vault.key_vault_id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_primary_key" {
  sensitive = true
  value     = azurerm_storage_account.storage_account.primary_access_key
}

# These are the bootstrap secrets used by the new FaCT
locals {
  # Common secrets for all envs
  base_bootstrap_secrets = [
    "cath-api-url",
    "os-key",
    "slack-channel-id",
    "slack-token"
  ]

  # functional tests run on the AAT environment and require additional secrets
  aat_bootstrap_secrets = [
    "func-test-client-secret",
    "func-viewer-test-client-secret"
  ]

  bootstrap_secrets     = var.env == "aat" ? concat(local.base_bootstrap_secrets, local.aat_bootstrap_secrets) : local.base_bootstrap_secrets
  bootstrap_prefix      = "${var.product}-bstrap-${var.env}"
  bootstrap_name_prefix = "bstrap"
}

data "azurerm_key_vault" "bootstrap_kv" {
  name                = "${local.bootstrap_prefix}-kv"
  resource_group_name = "${local.bootstrap_prefix}-rg"
}

data "azurerm_key_vault_secret" "bootstrap_secrets" {
  for_each     = { for secret in local.bootstrap_secrets : secret => secret }
  name         = each.value
  key_vault_id = data.azurerm_key_vault.bootstrap_kv.id
}

resource "azurerm_key_vault_secret" "bootstrap_secrets" {
  for_each     = data.azurerm_key_vault_secret.bootstrap_secrets
  key_vault_id = module.key_vault.key_vault_id
  name         = "${local.bootstrap_name_prefix}-${each.value.name}"
  value        = each.value.value
  tags = merge(var.common_tags, {
    "source" : "bootstrap ${data.azurerm_key_vault.bootstrap_kv.name} secrets"
  })
  content_type    = "Manual Secret"
  expiration_date = timeadd(timestamp(), "17520h")
}
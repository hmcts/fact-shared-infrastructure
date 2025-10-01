# New keyvault for FaCT
data "azurerm_resource_group" "mi_resource_group" {
    name = "managed-identities-${var.env}-rg"
}

data "azurerm_user_assigned_identity" "fact_mi" {
    name = "${var.product}-${var.env}-mi"
    resource_group_name = data.azurerm_resource_group.mi_resource_group
}


module "key_vault" {
  source              = "git@github.com:hmcts/cnp-module-key-vault?ref=master"
  name                = "${var.product}-kv-${var.env}"
  product             = var.product
  env                 = var.env
  object_id           = var.jenkins_AAD_objectId
  resource_group_name = azurerm_resource_group.rg.name
  product_group_name  = "DTS FaCT"

  common_tags         = var.common_tags
  managed_identity_object_ids = [data.azurerm_user_assigned_identity.fact_mi.principal_id]
}
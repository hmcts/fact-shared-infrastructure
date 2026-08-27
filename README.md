# fact-shared-infrastructure

Terraform for shared Azure infrastructure used by FaCT.

This repository currently contains resources for both the legacy (old) FaCT platform and the current (new) FaCT platform. The sections below are split so the old-platform documentation can be removed in one pass when decommissioning is complete.

## Infrastructure Split At A Glance

| Area | New FaCT | Old FaCT (legacy) |
| --- | --- | --- |
| Key Vault module | `module "key_vault"` in `keyvault.tf` | `module "key-vault"` in `main.tf` |
| App Insights | `app_insights.tf` | `appinsights_ia.tf` |
| Bootstrap and calculated secrets | `keyvault-bootstrap-secrets.tf`, `keyvault-secrets.tf` | Not present |
| Storage account and blob containers | Not present | `main.tf` |

## Repository Layout

| File | What it manages | Scope |
| --- | --- | --- |
| `state.tf` | Terraform backend and provider versions | Common |
| `variables.tf` | Shared input variables | Common |
| `main.tf` | Resource group, legacy key vault module, legacy storage resources, legacy storage outputs | Mixed (common + old) |
| `keyvault.tf` | New FaCT key vault and managed identity access | New |
| `keyvault-bootstrap-secrets.tf` | Copies bootstrap secrets from `fact-bstrap-<env>-kv` into new key vault with `bstrap-` prefix | New |
| `keyvault-secrets.tf` | Calculated secrets from Azure AD app registrations and generated session secret | New |
| `app_insights.tf` | New FaCT App Insights and connection string secret | New |
| `appinsights_ia.tf` | Legacy App Insights and legacy App Insights secrets | Old |
| `Jenkinsfile_CNP` | CI/CD pipeline entrypoint (`withInfraPipeline`) | Common |

## Common Infrastructure

The following are shared foundations for both old and new FaCT resources:

- Azure resource group: `azurerm_resource_group.rg` named `<product>-<env>`.
- Providers and versions are pinned in `state.tf`:
  - `hashicorp/azurerm` `4.81.0`
  - `hashicorp/azuread` `2.53.1`
  - `hashicorp/http` `3.6.1`
  - `hashicorp/random` `3.9.0`
- Core variables in `variables.tf`:
  - `env` (required)
  - `tenant_id` (required)
  - `jenkins_AAD_objectId` (required)
  - `common_tags` (required map)
  - `product` (default: `fact`)
  - `location` (default: `UK South`)

## New FaCT Infrastructure

The new FaCT resources are primarily in `keyvault.tf`, `keyvault-bootstrap-secrets.tf`, `keyvault-secrets.tf`, and `app_insights.tf`.

### Key Vault (`keyvault.tf`)

- Creates `module "key_vault"` (note underscore) with name pattern `fact-kv-<env>`.
- Grants access to:
  - FaCT managed identity `fact-<env>-mi`
  - Jenkins managed identity `jenkins-<env>-mi`
- Enables preview Jenkins access when `env == "aat"`.

### Bootstrap Secrets (`keyvault-bootstrap-secrets.tf`)

- Reads bootstrap vault `fact-bstrap-<env>-kv` in `fact-bstrap-<env>-rg`.
- Copies selected secrets into the new key vault with `bstrap-` prefix.
- Always copied:
  - `admin-frontend-client-secret`
  - `cath-api-url`
  - `os-key`
  - `public-frontend-client-secret`
  - `slack-channel-id`
  - `slack-token`
  - `cron-trigger-client-secret`
  - `sso-client-id`
  - `sso-client-secret`
  - `sso-tenant-id`
- Additional for `aat` only:
  - `func-test-client-secret`
  - `func-viewer-test-client-secret`
  - `jenkins-sso-client-id`
  - `jenkins-sso-client-secret`
  - `devl-sso-tenant-id`

### Calculated Secrets (`keyvault-secrets.tf`)

- Reads Azure AD app registrations based on environment suffix (`prod` vs `non-prod`).
- Writes calculated client IDs to key vault:
  - `api-app-reg-id`
  - `public-frontend-app-reg-id`
  - `admin-frontend-app-reg-id`
  - `fact-cron-trigger-app-reg-id`
- Functional-test secrets for `aat` only:
  - `func-test-client-app-id`
  - `func-test-viewer-client-app-id`
  - `func-test-tenant-id`
- Generates and stores `session-secret` via `random_password`.

### App Insights (`app_insights.tf`)

- Creates App Insights module `app_insights` named `fact-ai` (with environment suffix applied by module).
- Stores connection string in new key vault as:
  - `app-insights-connection-string`

<!-- BEGIN: OLD-FACT-INFRA -->
## Old FaCT Infrastructure (Legacy)

Legacy resources are primarily in `main.tf` and `appinsights_ia.tf`.

### Legacy Key Vault (`main.tf`)

- Uses `module "key-vault"` (note hyphen) from `cnp-module-key-vault`.
- This is separate from the new `module "key_vault"` and has different references.

### Legacy Storage (`main.tf`)

- Creates storage account `azurerm_storage_account.storage_account`.
- Creates public containers:
  - `images`
  - `csv`
- Optional image seed blobs from `local.images` (currently empty list).
- Stores storage secrets in legacy key vault:
  - `storage-account-name`
  - `storage-account-primary-key`
  - `storage-account-connection-string`
- Exposes outputs:
  - `storage_account_name`
  - `storage_account_primary_key` (sensitive)

### Legacy App Insights (`appinsights_ia.tf`)

- Creates App Insights module `application_insights_new` named `fact-appinsights-ai`.
- Stores legacy App Insights secrets in legacy key vault:
  - `AppInsightsInstrumentationKey-ai`
  - `app-insights-connection-string-ai`
<!-- END: OLD-FACT-INFRA -->

## CI/CD

- Jenkins pipeline definition is in `Jenkinsfile_CNP`.
- Backstage metadata is in `catalog-info.yaml`.
- Jenkins job annotation: `cft:HMCTS_d_to_i/fact-shared-infrastructure`.

## Notes For Maintainers

- There are two key vault module handles with similar names:
  - Legacy: `module.key-vault`
  - New: `module.key_vault`
- Be careful to reference the correct module when adding/updating secrets.
- `main.tf` mixes common and legacy resources; if legacy resources are removed, keep shared resources that are still required by new FaCT.




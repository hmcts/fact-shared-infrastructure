terraform {
  backend "azurerm" {}

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.8.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}

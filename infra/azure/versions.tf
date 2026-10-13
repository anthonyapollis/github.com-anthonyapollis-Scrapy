terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    azuread = { source = "hashicorp/azuread", version = "~> 3.0" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
  }

  # Local state by default. For a team, uncomment and create the storage account first
  # (see README.md).
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate..."
  #   container_name       = "tfstate"
  #   key                  = "data-dev.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none" # providers are registered explicitly in main.tf
}

provider "azuread" {}

locals {
  prefix = "${var.project}-${var.environment}"
  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Register the resource providers this setup uses (safe to re-run)
resource "azurerm_resource_provider_registration" "required" {
  for_each = toset([
    "Microsoft.Databricks",
    "Microsoft.DataFactory",
    "Microsoft.Storage",
    "Microsoft.Compute",
    "Microsoft.Network",
    "Microsoft.ManagedIdentity",
    "Microsoft.DBforPostgreSQL",
  ])
  name = each.value
}

resource "azurerm_resource_group" "data" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

# Data Lake Storage Gen2 (hierarchical namespace enabled)
resource "azurerm_storage_account" "lake" {
  name                     = "st${replace(local.prefix, "-", "")}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "raw"
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_data_factory" "adf" {
  name                = "adf-${local.prefix}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_resource_provider_registration.required]
}

resource "azurerm_databricks_workspace" "dbw" {
  name                        = "dbw-${local.prefix}"
  resource_group_name         = azurerm_resource_group.data.name
  location                    = azurerm_resource_group.data.location
  sku                         = var.databricks_sku
  managed_resource_group_name = "rg-${local.prefix}-dbx-managed"
  tags                        = local.tags

  depends_on = [azurerm_resource_provider_registration.required]
}

# Cost guard-rail: alerts at 80% and 100% of the monthly budget
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-${local.prefix}"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = var.alert_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_emails = var.alert_emails
  }
}

resource "random_password" "pg_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*-_=+"
}

resource "azurerm_postgresql_flexible_server" "pg" {
  name                          = "psql-${local.prefix}-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.data.name
  location                      = azurerm_resource_group.data.location
  version                       = "16"
  administrator_login           = "pgadmin"
  administrator_password        = random_password.pg_admin.result
  sku_name                      = var.postgres_sku
  storage_mb                    = 32768
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = true
  tags                          = local.tags

  depends_on = [azurerm_resource_provider_registration.required]
}

resource "azurerm_postgresql_flexible_server_database" "appdb" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.pg.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Lets Azure services (Data Factory, Databricks) connect
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Lets your own machine connect (created only when my_ip is set)
resource "azurerm_postgresql_flexible_server_firewall_rule" "my_ip" {
  count            = var.my_ip == "" ? 0 : 1
  name             = "allow-my-ip"
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = var.my_ip
  end_ip_address   = var.my_ip
}

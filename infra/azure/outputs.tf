output "resource_group" {
  value = azurerm_resource_group.data.name
}

output "databricks_url" {
  value = "https://${azurerm_databricks_workspace.dbw.workspace_url}"
}

output "data_factory" {
  value = azurerm_data_factory.adf.name
}

output "storage_account" {
  value = azurerm_storage_account.lake.name
}

output "data_team_group" {
  value = azuread_group.data_team.display_name
}

output "postgres_host" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "postgres_admin_user" {
  value = azurerm_postgresql_flexible_server.pg.administrator_login
}

output "postgres_admin_password" {
  value     = random_password.pg_admin.result
  sensitive = true
}

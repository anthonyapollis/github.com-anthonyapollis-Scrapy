# Team: Contributor on the resource group (covers Databricks, Data Factory, storage management)
resource "azurerm_role_assignment" "team_rg" {
  scope                = azurerm_resource_group.data.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.data_team.object_id
}

# Contributor does not grant access to the data inside storage, so add the data role separately
resource "azurerm_role_assignment" "team_lake_data" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.data_team.object_id
}

# Data Factory's managed identity can read and write the lake
resource "azurerm_role_assignment" "adf_lake_data" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

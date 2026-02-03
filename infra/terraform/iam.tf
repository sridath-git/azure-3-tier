#State RG lookup 
data "azurerm_resource_group" "tfstate_rg" {
  name = "azure-3-tier-3tier-tfstate-rg"
}


resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.cicd_sp_object_id
}

# CI to read/write tfstate
resource "azurerm_role_assignment" "tfstate_blob_contrib" {
  scope                = data.azurerm_resource_group.tfstate_rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.cicd_sp_object_id
}


#resource "azurerm_role_assignment" "deploy_rg_contributor" {
# scope                = azurerm_resource_group.rg.id
#role_definition_name = "Contributor"
#principal_id         = var.cicd_sp_object_id
#}


resource "azurerm_role_assignment" "api_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
}

resource "azurerm_role_assignment" "web_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.web.identity[0].principal_id
}
resource "azurerm_role_assignment" "api_slot_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app_slot.api_staging.identity[0].principal_id
}

resource "azurerm_role_assignment" "web_slot_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app_slot.web_staging.identity[0].principal_id
}

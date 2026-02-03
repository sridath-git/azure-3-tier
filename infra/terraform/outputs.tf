output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
output "acr_name" {
  value = azurerm_container_registry.acr.name
}

# App Services (production)
output "api_app_name" {
  value = azurerm_linux_web_app.api.name
}

output "web_app_name" {
  value = azurerm_linux_web_app.web.name
}

output "api_app_id" {
  value = azurerm_linux_web_app.api.id
}

output "web_app_id" {
  value = azurerm_linux_web_app.web.id
}

output "api_staging_slot_name" {
  value = azurerm_linux_web_app_slot.api_staging.name
}
# Deployment slots (staging)
output "web_staging_slot_name" {
  value = azurerm_linux_web_app_slot.web_staging.name
}
#DB
output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "db_name" {
  value = var.db_name
}


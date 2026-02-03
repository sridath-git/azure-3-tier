# API diagnostics
resource "azurerm_monitor_diagnostic_setting" "api_diag" {
  name                       = "${var.project_name}-api-diag"
  target_resource_id         = azurerm_linux_web_app.api.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServicePlatformLogs" }

  enabled_metric { category = "AllMetrics" }
}

# API STAGING slot diagnostics
resource "azurerm_monitor_diagnostic_setting" "api_staging_diag" {
  name                       = "${var.project_name}-api-staging-diag"
  target_resource_id         = azurerm_linux_web_app_slot.api_staging.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServicePlatformLogs" }

  enabled_metric { category = "AllMetrics" }
}

# WEB diagnostics
resource "azurerm_monitor_diagnostic_setting" "web_diag" {
  name                       = "${var.project_name}-web-diag"
  target_resource_id         = azurerm_linux_web_app.web.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServicePlatformLogs" }

  enabled_metric { category = "AllMetrics" }
}

# WEB STAGING slot diagnostics
resource "azurerm_monitor_diagnostic_setting" "web_staging_diag" {
  name                       = "${var.project_name}-web-staging-diag"
  target_resource_id         = azurerm_linux_web_app_slot.web_staging.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServicePlatformLogs" }

  enabled_metric { category = "AllMetrics" }
}

# Postgres diagnostics
resource "azurerm_monitor_diagnostic_setting" "pg_diag" {
  name                       = "${var.project_name}-pg-diag"
  target_resource_id         = azurerm_postgresql_flexible_server.pg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  enabled_log { category = "PostgreSQLLogs" }
  enabled_metric { category = "AllMetrics" }
}

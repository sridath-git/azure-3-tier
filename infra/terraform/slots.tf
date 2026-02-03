resource "azurerm_linux_web_app_slot" "api_staging" {
  name                      = "staging"
  app_service_id            = azurerm_linux_web_app.api.id
  virtual_network_subnet_id = azurerm_subnet.appsvc.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    container_registry_use_managed_identity = true
    health_check_path                       = "/health"
    health_check_eviction_time_in_min       = 2
    vnet_route_all_enabled                  = false


    application_stack {
      docker_image_name   = local.api_image
      docker_registry_url = "https://${local.acr_server}"
    }
  }

  # inherit all env vars from production
  app_settings = merge({
    WEBSITES_PORT                       = "3000"
    PORT                                = "3000"
    WEBSITE_CONTAINER_START_TIME_LIMIT  = "600"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"


    DBHOST = "azure-3-tier-3tier-pg.private.postgres.database.azure.com"
    DBPORT = "5432"

    # IMPORTANT: flexible server login format
    DBUSER = "pgadmin"
    DBPASS = var.db_admin_password
    DB     = "appdb"
    },
    {
      APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.api_ai.connection_string
      APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.api_ai.instrumentation_key
    }
  )
  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_name,
      app_settings["DOCKER_CUSTOM_IMAGE_NAME"],
      app_settings["DOCKER_REGISTRY_SERVER_URL"],
      app_settings["ACR_USE_MANAGED_IDENTITY_CREDENTIALS"],
    ]
  }
}

resource "azurerm_linux_web_app_slot" "web_staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.web.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    container_registry_use_managed_identity = true
    health_check_path                       = "/health"
    health_check_eviction_time_in_min       = 2

    application_stack {
      docker_image_name   = local.web_image
      docker_registry_url = "https://${local.acr_server}"
    }
  }

  # inherit prod settings BUT override API_HOST to call API staging
  app_settings = merge(
    azurerm_linux_web_app.web.app_settings,
    {
      API_HOST = local.api_staging_host
    },
    {
      APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.web_ai.connection_string
      APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.web_ai.instrumentation_key
    }
  )
  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_name,
      app_settings["DOCKER_CUSTOM_IMAGE_NAME"],
      app_settings["DOCKER_REGISTRY_SERVER_URL"],
      app_settings["ACR_USE_MANAGED_IDENTITY_CREDENTIALS"],
    ]
  }
}

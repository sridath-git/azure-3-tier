resource "azurerm_service_plan" "asp" {
  name                = "${var.project_name}-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "S1"
  worker_count        = 2
}

locals {
  acr_server = azurerm_container_registry.acr.login_server

  api_image = "azure-3-tier-api:${var.api_image_tag}"
  web_image = "azure-3-tier-web:${var.web_image_tag}"

  api_prod_host         = "https://${azurerm_linux_web_app.api.default_hostname}"
  api_staging_host      = "https://${azurerm_linux_web_app.api.name}-staging.azurewebsites.net"
  postgres_private_fqdn = "${azurerm_postgresql_flexible_server.pg.name}.private.postgres.database.azure.com"

}

resource "azurerm_linux_web_app" "api" {
  name                      = "${var.project_name}-api"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  service_plan_id           = azurerm_service_plan.asp.id
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

  app_settings = merge(
    {
      WEBSITES_PORT                       = "3000"
      PORT                                = "3000"
      WEBSITE_CONTAINER_START_TIME_LIMIT  = "600"
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"

      DBHOST = "azure-3-tier-3tier-pg.private.postgres.database.azure.com"
      DBUSER = "pgadmin"
      DBPORT = "5432"
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
      tags
    ]
  }
}

resource "azurerm_linux_web_app" "web" {
  name                = "${var.project_name}-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id

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

  app_settings = merge({
    WEBSITES_PORT = "3000"
    PORT          = "3000"

    # Production web calls production API
    API_HOST = local.api_prod_host
    }, {
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
      tags
    ]
  }
}

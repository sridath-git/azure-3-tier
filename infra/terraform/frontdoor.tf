resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = "${var.project_name}-fd"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = "${var.project_name}-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
}

resource "azurerm_cdn_frontdoor_origin_group" "web_og" {
  name                     = "${var.project_name}-web-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  session_affinity_enabled = false
  health_probe {
    interval_in_seconds = 30
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    successful_samples_required = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "web_origin" {
  name                           = "${var.project_name}-web-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.web_og.id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = azurerm_linux_web_app.web.default_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_linux_web_app.web.default_hostname
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_route" "web_route" {
  name                          = "${var.project_name}-web-route"
  enabled                       = true
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web_og.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.web_origin.id]

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true

  patterns_to_match      = ["/", "/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = true
  cache {
    query_string_caching_behavior = "UseQueryString"
    compression_enabled           = false
  }
}


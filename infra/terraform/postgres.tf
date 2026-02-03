resource "azurerm_private_dns_zone" "pg" {
  name                = "private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg_link" {
  name                  = "azure-3-tier-3tier-pgdnslink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
resource "azurerm_private_dns_a_record" "pg_fqdn" {
  name                = "azure-3-tier-3tier-pg"
  zone_name           = azurerm_private_dns_zone.pg.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = ["10.10.2.4"]
}

resource "azurerm_postgresql_flexible_server" "pg" {
  name                = "azure-3-tier-3tier-pg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = "pgadmin"
  administrator_password = var.db_admin_password

  version    = "16"
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  zone       = "2"


  public_network_access_enabled = false

  delegated_subnet_id          = azurerm_subnet.postgres.id
  private_dns_zone_id          = azurerm_private_dns_zone.pg.id
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false # set true if you want, depends on region/SKU support
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.pg_link
  ]
}


resource "azurerm_postgresql_flexible_server_database" "appdb" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.pg.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

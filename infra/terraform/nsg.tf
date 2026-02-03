resource "azurerm_network_security_group" "pg_nsg" {
  name                = "azure-3-tier-3tier-pg-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "pg_subnet_assoc" {
  subnet_id                 = azurerm_subnet.postgres.id
  network_security_group_id = azurerm_network_security_group.pg_nsg.id
}



resource "azurerm_network_security_rule" "allow_api_to_pg" {
  name                        = "allow-api-to-pg"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = azurerm_subnet.appsvc.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.pg_nsg.name
}

resource "azurerm_network_security_rule" "deny_all_pg" {
  name                        = "deny-all-pg"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.pg_nsg.name
}

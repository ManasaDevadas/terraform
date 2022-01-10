
resource "azurerm_resource_group" "web-vnet-rg" {
    name     = var.web_vnet_rg_name
    location = var.location
    tags      = {
      Env = var.system
    }
}
#Create virtual network
resource "azurerm_virtual_network" "web-vnet" {
    name                = var.webvnet_name
    address_space       = var.webvnet_address_space
    location            = azurerm_resource_group.web-vnet-rg.location
    resource_group_name = azurerm_resource_group.web-vnet-rg.name
}

# Create subnet for web servers
resource "azurerm_subnet" "websubnet" {
  name                 = "${var.webvnet_name}-websubnet"
  resource_group_name  = azurerm_resource_group.web-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.web-vnet.name
  address_prefixes      = var.websubnet_address_space
}

# Create subnet for LB
resource "azurerm_subnet" "webLBsubnet" {
  name                 = "${var.webvnet_name}-LBsubnet"
  resource_group_name  = azurerm_resource_group.web-vnet-rg.name
  virtual_network_name = azurerm_virtual_network.web-vnet.name
  address_prefixes      = var.webLBsubnet_address_space
}

  resource "azurerm_public_ip" "webnat" {
  name                = "webnat-gateway-publicIP"
  location            = azurerm_resource_group.web-vnet-rg.location
  resource_group_name = azurerm_resource_group.web-vnet-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

  resource "azurerm_nat_gateway" "webnat" {
  name                = "web-natgateway"
  location            = azurerm_resource_group.web-vnet-rg.location
  resource_group_name = azurerm_resource_group.web-vnet-rg.name
  public_ip_address_ids   = [azurerm_public_ip.webnat.id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "azurerm_subnet_nat_gateway_association" "webnat" {
  subnet_id      = azurerm_subnet.websubnet.id
  nat_gateway_id = azurerm_nat_gateway.webnat.id
}
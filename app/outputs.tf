output "webvnet_id" {
  description = "The id of the newly created vNet"
  value       = azurerm_virtual_network.web-vnet.id
}

output "webvnet_name" {
  description = "The Name of the newly created vNet"
  value       = azurerm_virtual_network.web-vnet.name
}


output "websubnet" {
  description = "The ids of subnets created inside the newl vNet"
  value       = azurerm_subnet.websubnet.id
}

output "webLBsubnet" {
  description = "The ids of subnets created inside the newl vNet"
  value       = azurerm_subnet.webLBsubnet.id
}
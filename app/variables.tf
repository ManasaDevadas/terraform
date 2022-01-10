variable "system" {
    type = string
    description = "Name of the system or environment"
}


variable "location" {
    type = string
    description = "Azure location of the web server environment"
    default = "westus2"

}

variable "web_vnet_rg_name" {
    type = string
    description = "web vnet Resource grp name"
}

variable "webvnet_name" {
    type = string
    description = "web vnet name"
}

variable "webvnet_address_space" { 
    type = list
    description = "Address space for Virtual Network"
}

variable "websubnet_address_space" { 
    type = list
    description = "Address space for web servers"
}

variable "webLBsubnet_address_space" { 
    type = list
    description = "Address space LB for web servers"
}

variable "web_rg_name" {
    type = string
    description = "web VM and lb Resource grp name"
}

variable "vmnameprefix" {
	type 				= string
	description	= "Prefix to use for VM Names"
}


variable "networkInterfaceName" {
	type 				= string
	default 		= "nic"
	description	= "default Network interface name"
}

variable "adminUsername" {
	type 				= string
	default 		= "azureuser"
	description	= "Default Admin username"
}




# Defining the local variables
locals {
  availabilitySetName       = "webAVSet"
  storageAccountType        = "Standard"
  loadBalancerName          = "web-ilb"
  networkSecurityGroupName  = "nsg"
  storageAccountName        = lower(join("", ["diag", "${random_string.asaname-01.result}"]))
  osDiskName                = join("",["${var.vmnameprefix}", "_OsDisk_1_", lower("${random_string.avmosd-01.result}")])
}

data "template_file" "apache-vm-cloud-init" {
  template = file("configureWeb.sh")
}

# Resource Group
resource "azurerm_resource_group" "webrg" {
  name      = var.web_rg_name
  location  = var.location
}

# Random string for storage account name  
resource "random_string" "asaname-01" {
  length  = 16
  special = "false"
}

# Storage account
resource "azurerm_storage_account" "asa-01" {
  name                      = local.storageAccountName
  resource_group_name       = azurerm_resource_group.webrg.name
  location                  = azurerm_resource_group.webrg.location
  account_tier              = local.storageAccountType
  account_replication_type  = "LRS"
}

# Avaliability set
resource "azurerm_availability_set" "avset" {
  name                         = local.availabilitySetName
  location                     = azurerm_resource_group.webrg.location
  resource_group_name          = azurerm_resource_group.webrg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Network interface
resource "azurerm_network_interface" "ani-01" {
  count               = 2
  name                = "${var.networkInterfaceName}${count.index}"
  location            = azurerm_resource_group.webrg.location
  resource_group_name = azurerm_resource_group.webrg.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.websubnet.id
  }
}

#Storage disk
 resource "azurerm_managed_disk" "datadisk" {
   count                = 4
   name                 = "datadisk_existing_${count.index}"
   location             = azurerm_resource_group.webrg.location
   resource_group_name  = azurerm_resource_group.webrg.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = "2"
 }



#Load Balancer
resource "azurerm_lb" "alb-01" {
  name                = local.loadBalancerName
  location            = azurerm_resource_group.webrg.location
  resource_group_name = azurerm_resource_group.webrg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = azurerm_subnet.webLBsubnet.id
    private_ip_address            = "10.0.1.6"
    private_ip_address_allocation = "Static"
  }
}

# Backend address pool
resource "azurerm_lb_backend_address_pool" "abp-01" {
  name                = "BackendPool1"
  resource_group_name = azurerm_resource_group.webrg.name
  loadbalancer_id     = azurerm_lb.alb-01.id
 depends_on = [
    azurerm_network_interface.ani-01,
  ]
}

# Associate network Interface and backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "assbp-01" {
  count                   = 2
  network_interface_id    = element(azurerm_network_interface.ani-01.*.id,count.index)
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.abp-01.id
}

# Probe
resource "azurerm_lb_probe" "albp-01" {
  name                = "lbprobe"
  resource_group_name = azurerm_resource_group.webrg.name
  port                = 80
  protocol            = "tcp"
  interval_in_seconds = 15
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.alb-01.id
}

# Loadbalancing rule
resource "azurerm_lb_rule" "albrule-01" {
  name                            = "lbrule"
  resource_group_name             = azurerm_resource_group.webrg.name
  backend_address_pool_id         = azurerm_lb_backend_address_pool.abp-01.id 
  probe_id                        = azurerm_lb_probe.albp-01.id
  protocol                        = "tcp"
  backend_port                    = 80
  frontend_port                   = 80
  idle_timeout_in_minutes         = 15
  frontend_ip_configuration_name  = "LoadBalancerFrontEnd"
  loadbalancer_id                 = azurerm_lb.alb-01.id
}



# Random string for OS disk
resource "random_string" "avmosd-01" {
  length  = 32
  special = "false"
}

# Create (and display) an SSH key
resource "tls_private_key" "web_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.web_ssh.private_key_pem 
    sensitive = true
}

# Virtual Machine
resource "azurerm_virtual_machine" "webvm01" {
  count                             = 2
  name                              = "${var.vmnameprefix}${count.index}"
  vm_size                           = "Standard_DS2_V2"
  resource_group_name               = azurerm_resource_group.webrg.name
  location                          = azurerm_resource_group.webrg.location
  availability_set_id               = azurerm_availability_set.avset.id
  network_interface_ids             = [element(azurerm_network_interface.ani-01.*.id, count.index)]
  delete_os_disk_on_termination     = true
  delete_data_disks_on_termination  = true

  os_profile {
    computer_name  = "${var.vmnameprefix}${count.index}"
    admin_username = var.adminUsername
    custom_data = base64encode(data.template_file.apache-vm-cloud-init.rendered)
 }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = tls_private_key.web_ssh.public_key_openssh
      path = "/home/${var.adminUsername}/.ssh/authorized_keys"
    }
  }
 storage_image_reference {
   publisher = "RedHat"
   offer =  "RHEL"
   sku =  "79-gen2"
   version = "latest"
 }

  storage_os_disk {
    name          = "${local.osDiskName}${count.index}"
    create_option = "FromImage"
  }
   storage_data_disk {
     name            = element(azurerm_managed_disk.datadisk.*.name, (count.index+count.index))
     managed_disk_id = element(azurerm_managed_disk.datadisk.*.id, (count.index+count.index))
     create_option   = "Attach"
     lun             = 0
     disk_size_gb    = element(azurerm_managed_disk.datadisk.*.disk_size_gb, count.index)
   }

    storage_data_disk {
     name            = element(azurerm_managed_disk.datadisk.*.name, (count.index+count.index+1))
     managed_disk_id = element(azurerm_managed_disk.datadisk.*.id, (count.index+count.index+1))
     create_option   = "Attach"
     lun             = 1
     disk_size_gb    = element(azurerm_managed_disk.datadisk.*.disk_size_gb, count.index)
   }


  
  boot_diagnostics {
    storage_uri = azurerm_storage_account.asa-01.primary_blob_endpoint
    enabled     = "true"
  }


}
 
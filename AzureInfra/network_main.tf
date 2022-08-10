# Create the network VNET
resource "azurerm_virtual_network" "mediavnet" {
  name 				  = var.mediavnet
  address_space 	  = [var.mediavnetcidr]
  location            = azurerm_resource_group.mediarg.location
  resource_group_name = azurerm_resource_group.mediarg.name
}

# Create a subnet for VMSS appservers
resource "azurerm_subnet" "appvmsubnet" {
  name 					= var.mediaappsubnet
  address_prefixes 		= [var.mediaappsubnetcidr]
  resource_group_name   = azurerm_resource_group.mediarg.name
  virtual_network_name = azurerm_virtual_network.mediavnet.name
}

# Create a subnet for DB VM
resource "azurerm_subnet" "dbvmsubnet" {
  name 					= var.mediadbsubnet
  address_prefixes 		= [var.mediadbsubnetcidr]
  resource_group_name   = azurerm_resource_group.mediarg.name
  virtual_network_name = azurerm_virtual_network.mediavnet.name
}

resource "azurerm_network_interface" "dbvmnic" {
   name                = "dbvmnic"
   location            = azurerm_resource_group.mediarg.location
   resource_group_name = azurerm_resource_group.mediarg.name

   ip_configuration {
     name                          = "dbvmnicconfig"
     subnet_id                     = azurerm_subnet.dbvmsubnet.id
     private_ip_address_allocation = "static"
     private_ip_address   = var.dbvmstaticip
   }

 }

# Get a Static Public IP
resource "azurerm_public_ip" "lbpublicip" {
   name                         = var.lbpublicipname
   location                     = azurerm_resource_group.mediarg.location
   resource_group_name          = azurerm_resource_group.mediarg.name
   allocation_method            = "Static"
   sku                          = "Standard"
}

resource "azurerm_lb" "mediaapplb" {
   name                = var.mediaapplbname
   location            = azurerm_resource_group.mediarg.location
   resource_group_name = azurerm_resource_group.mediarg.name
   sku                 = "Standard"

   frontend_ip_configuration {
     name                 = "frontpubip"
     public_ip_address_id = azurerm_public_ip.lbpublicip.id
   }
 }

 resource "azurerm_lb_backend_address_pool" "lbappbp" {
   loadbalancer_id     = azurerm_lb.mediaapplb.id
   name                = var.lbappbpname
 }

 resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = azurerm_resource_group.mediarg.name
  name                           = "ssh"
  loadbalancer_id                = azurerm_lb.mediaapplb.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "frontpubip"
}

resource "azurerm_lb_probe" "lbprobe" {
  //resource_group_name = azurerm_resource_group.mediarg.name
  loadbalancer_id     = azurerm_lb.mediaapplb.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/"
  port                = 8080
}

resource "azurerm_lb_rule" "applbrule" {
   //resource_group_name            = azurerm_resource_group.mediarg.name
   loadbalancer_id                = azurerm_lb.mediaapplb.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = 8080
   backend_port                   = 8080
   backend_address_pool_id        = azurerm_lb_backend_address_pool.lbappbp.id
   frontend_ip_configuration_name = "frontpubip"
   probe_id                       = azurerm_lb_probe.lbprobe.id
}


output "mediapplb" {
  value = azurerm_lb.mediaapplb
}
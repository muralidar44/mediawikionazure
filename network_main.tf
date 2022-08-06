# Create the network VNET
resource "azurerm_virtual_network" "mediavnet" {
  name 				  = var.mediavnet
  address_space 	  = [var.mediavnetcidr]
  location            = azurerm_resource_group.mediarg.location
  resource_group_name = azurerm_resource_group.mediarg.name
}

# Create a subnet for VM
resource "azurerm_subnet" "websubnet" {
  name 					= [var.mediawebsubnet]
  address_prefixes 		= [var.mediawebsubnetcidr]
  resource_group_name   = azurerm_resource_group.mediarg.name
  virtual_network_name = azurerm_virtual_network.mediavnet.name
}

# Get a Static Public IP
resource "azurerm_public_ip" "lbpublicip" {
   name                         = [var.lbpublicipname]
   location                     = azurerm_resource_group.mediarg.location
   resource_group_name          = azurerm_resource_group.mediarg.name
   allocation_method            = "Static"
}

 resource "azurerm_lb" "medialb" {
   name                = [var.medialbname]
   location            = azurerm_resource_group.mediarg.location
   resource_group_name = azurerm_resource_group.mediarg.name

   frontend_ip_configuration {
     name                 = "frontpubip"
     public_ip_address_id = azurerm_public_ip.lbpublicip.id
   }
 }

 resource "azurerm_lb_backend_address_pool" "lbbp" {
   loadbalancer_id     = azurerm_lb.medialb.id
   name                = [var.lbbackendpoolname]
 }

 resource "azurerm_network_interface" "webappnics" {
   count               = 2
   name                = "webnic${count.index}"
   location            = azurerm_resource_group.mediarg.location
   resource_group_name = azurerm_resource_group.mediarg.name

   ip_configuration {
     name                          = "vmnicconfig"
     subnet_id                     = azurerm_subnet.websubnet.id
     private_ip_address_allocation = "static"
   }
 }
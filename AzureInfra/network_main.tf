# Create the Virtual network

resource "azurerm_virtual_network" "mediavnet" {
  name 				  = var.mediavnet
  address_space 	  = [var.mediavnetcidr]
  location            = azurerm_resource_group.mediarg.location
  resource_group_name = azurerm_resource_group.mediarg.name
}

# Create a subnet for appservers
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

# create a NIC resource for database VM
resource "azurerm_network_interface" "dbvmnic" {
   name                = "dbvmnic"
   location            = azurerm_resource_group.mediarg.location
   resource_group_name = azurerm_resource_group.mediarg.name

   ip_configuration {
     name                          = "dbvmnicconfig"
     subnet_id                     = azurerm_subnet.dbvmsubnet.id
     private_ip_address_allocation = "Static"
     private_ip_address   = var.dbvmstaticip               
   }

 }

#associate lb rule to db vm
 resource "azurerm_network_interface_nat_rule_association" "dbnatruleasso" {
  network_interface_id  = azurerm_network_interface.dbvmnic.id
  ip_configuration_name = "dbvmnicconfig"
  nat_rule_id           = azurerm_lb_nat_rule.dbnatrule.id
}

#creating db vm as backend pool for LB
resource "azurerm_network_interface_backend_address_pool_association" "dbnicbpasso" {
  network_interface_id    = azurerm_network_interface.dbvmnic.id
  ip_configuration_name   = "dbvmnicconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbdbbp.id
}

# Get a Static Public IP for load balancer
resource "azurerm_public_ip" "lbpublicip" {
   name                         = var.lbpublicipname
   location                     = azurerm_resource_group.mediarg.location
   resource_group_name          = azurerm_resource_group.mediarg.name
   allocation_method            = "Static"
   sku                          = "Standard"
}

resource "azurerm_public_ip" "lbpublicipout" {
   name                         = "dbpubout"
   location                     = azurerm_resource_group.mediarg.location
   resource_group_name          = azurerm_resource_group.mediarg.name
   allocation_method            = "Static"
   sku                          = "Standard"
}

#create load balancer
resource "azurerm_lb" "mediaapplb" {
   name                = var.mediaapplbname
   location            = azurerm_resource_group.mediarg.location
   resource_group_name = azurerm_resource_group.mediarg.name
   sku                 = "Standard"

   frontend_ip_configuration {
     name                 = "frontpubip"
     public_ip_address_id = azurerm_public_ip.lbpublicip.id
   }
   frontend_ip_configuration {
     name                 = "dboutpublicip"
     public_ip_address_id = azurerm_public_ip.lbpublicipout.id
   }
 }

#create backend pool for appservers
 resource "azurerm_lb_backend_address_pool" "lbappbp" {
   loadbalancer_id     = azurerm_lb.mediaapplb.id
   name                = var.lbappbpname
 }

 #create backend pool for db server
  resource "azurerm_lb_backend_address_pool" "lbdbbp" {
   loadbalancer_id     = azurerm_lb.mediaapplb.id
   name                = "db"
 }

#create natpool for app servers
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

resource "azurerm_lb_nat_rule" "dbnatrule" {
  resource_group_name            = azurerm_resource_group.mediarg.name
  loadbalancer_id                = azurerm_lb.mediaapplb.id
  name                           = "sshaccess"
  protocol                       = "Tcp"
  frontend_port                  = 52000
  backend_port                   = 22
  frontend_ip_configuration_name = "dboutpublicip"
}

#create health probe
resource "azurerm_lb_probe" "lbprobe" {
  //resource_group_name = azurerm_resource_group.mediarg.name
  loadbalancer_id     = azurerm_lb.mediaapplb.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/"
  port                = 80
}

#create LB rule for webtraffic 
resource "azurerm_lb_rule" "applbrule" {
   //resource_group_name            = azurerm_resource_group.mediarg.name
   loadbalancer_id                = azurerm_lb.mediaapplb.id
   name                           = "webtrafficrule"
   protocol                       = "Tcp"
   frontend_port                  = 80
   backend_port                   = 80
   backend_address_pool_ids        = [azurerm_lb_backend_address_pool.lbappbp.id]
   frontend_ip_configuration_name = "frontpubip"
   probe_id                       = azurerm_lb_probe.lbprobe.id
}
resource "azurerm_lb_rule" "dblbrule" {
   //resource_group_name            = azurerm_resource_group.mediarg.name
   loadbalancer_id                = azurerm_lb.mediaapplb.id
   name                           = "dbtraffic"
   protocol                       = "Tcp"
   frontend_port                  = 8080
   backend_port                   = 8080
   backend_address_pool_ids        = [azurerm_lb_backend_address_pool.lbdbbp.id]
   frontend_ip_configuration_name = "frontpubip"
   probe_id                       = azurerm_lb_probe.lbprobe.id
}

resource "azurerm_lb_outbound_rule" "lboutboundrule" {
  name                    = "dboutrule"
  loadbalancer_id         = azurerm_lb.mediaapplb.id
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbdbbp.id

  frontend_ip_configuration {
    name = "dboutpublicip"
  }
}


output "mediapplb" {
  value = azurerm_lb.mediaapplb
}
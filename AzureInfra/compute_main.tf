#Create Resource Group
resource "azurerm_resource_group" "mediarg" {
   name     = var.mediavnet
   location = var.region
 }

#Create Database virtual machine
resource "azurerm_virtual_machine" "dbvm" {
   name                  = "dbvm"
   location              = azurerm_resource_group.mediarg.location   
   resource_group_name   = azurerm_resource_group.mediarg.name
   network_interface_ids = [azurerm_network_interface.dbvmnic.id]
   vm_size               = "Standard_D4s_v3"

   # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

   # Uncomment this line to delete the data disks automatically when deleting the VM
   # delete_data_disks_on_termination = true
   storage_image_reference {
     publisher = "Canonical"
     offer     = "UbuntuServer"
     sku       = "18.04-LTS"
     version   = "latest"
   }

   storage_os_disk {
     name              = "myosdiskb"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }

   
   os_profile {
     computer_name  = "hostnameb"
     admin_username = "testadmin"
     admin_password = "Password1234!"
   }

   os_profile_linux_config {
     disable_password_authentication = false
   }

}

#Create VMSS for app servers

 resource "azurerm_virtual_machine_scale_set" "appvmss" {
  name                = "appwebvmssb"
  location            = azurerm_resource_group.mediarg.location
  resource_group_name = azurerm_resource_group.mediarg.name

  # automatic rolling upgrade
  automatic_os_upgrade = false
  upgrade_policy_mode  = "Manual"

  // rolling_upgrade_policy {
  // max_batch_instance_percent              = 50
  // max_unhealthy_instance_percent          = 50
  // max_unhealthy_upgraded_instance_percent = 5
  // pause_time_between_batches              = "PT0S"
  // }

  # required when using rolling upgrade policy
  health_probe_id = azurerm_lb_probe.lbprobe.id
    sku {
    name     = "Standard_D4s_v3"
    tier     = "Standard"
    capacity = 2
  }

   storage_profile_image_reference {
     publisher = "Canonical"
     offer     = "UbuntuServer"
     sku       = "18.04-LTS"
     version   = "latest"
   }

   storage_profile_os_disk {
     name              = ""
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }

   os_profile {
  
  computer_name_prefix  = "appvm"
  admin_username = "azureuser"
  admin_password = "Password1234!"
   }

   os_profile_linux_config {
     disable_password_authentication = false
   }
network_profile {
    name    = "appvmnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "appvmconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.appvmsubnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lbappbp.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.lbnatpool.id]
    }
  }
 }

 output "dbvm" {
  value = azurerm_virtual_machine.dbvm
  sensitive = true
}

output "appvmss" {
  value = azurerm_virtual_machine_scale_set.appvmss
  sensitive = true
}
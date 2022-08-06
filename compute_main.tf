# Generate random password
resource "random_password" "linux-vm-password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  number           = true
  special          = true
  override_special = "!@#$%&"
}

resource "azurerm_availability_set" "mediaavset" {
   name                         = [var.mediaavsetname]
   location                     = azurerm_resource_group.mediarg.location
   resource_group_name          = azurerm_resource_group.mediarg.name
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
 }

 resource "azurerm_virtual_machine" "webapp" {
   count                 = 2
   name                  = "webvm${count.index}"
   location              = azurerm_resource_group.mediarg.location
   availability_set_id   = azurerm_availability_set.mediaavset.id
   resource_group_name   = azurerm_resource_group.mediarg.name
   network_interface_ids = [element(azurerm_network_interface.webvmnics.*.id, count.index)]
   vm_size               = [var.vmsku]

   # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

   # Uncomment this line to delete the data disks automatically when deleting the VM
   # delete_data_disks_on_termination = true

   storage_image_reference {
     publisher = var.webvm_image_publisher
     offer     = var.webvm_image_offer
     sku       = var.rhel_8_2_sku
     version   = "latest"
   }

   storage_os_disk {
     name              = "myosdisk${count.index}"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }

   
   os_profile {
  count                 = 2
  computer_name  = "webvmcomputer${count.index}"
  admin_username = var.linux_admin_username
  admin_password = random_password.linux-vm-password.result
   }

   os_profile_linux_config {
     disable_password_authentication = false
   }

   tags = {
     environment = "staging"
   }
 }
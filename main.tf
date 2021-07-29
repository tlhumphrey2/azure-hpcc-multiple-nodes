provider "azurerm" {
  version = "=1.44.0"
}

resource "azurerm_resource_group" "hpcc" {
 name     = "${var.resource_group_name}"
 location = "eastus2"
}

resource "azurerm_virtual_network" "hpcc" {
 name                = "hpcc-vn"
 address_space       = ["10.0.0.0/16"]
 location            = azurerm_resource_group.hpcc.location
 resource_group_name = azurerm_resource_group.hpcc.name
}

resource "azurerm_subnet" "hpcc" {
 name                 = "acctsub"
 resource_group_name  = azurerm_resource_group.hpcc.name
 virtual_network_name = azurerm_virtual_network.hpcc.name
 address_prefix       = "10.0.2.0/24"
}

resource "azurerm_availability_set" "avset" {
 name                         = "avset"
 location                     = azurerm_resource_group.hpcc.location
 resource_group_name          = azurerm_resource_group.hpcc.name
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}

resource "azurerm_public_ip" "hpcc-thor" {
 count                        = "${var.thornodes}"
 name                         = "thor-public-ip-${count.index}"
 location                     = azurerm_resource_group.hpcc.location
 resource_group_name          = azurerm_resource_group.hpcc.name
 allocation_method            = "Static"
}

resource "azurerm_network_interface" "hpcc-thor" {
 count               = "${var.thornodes}"
 name                = "thor-ni-${count.index}"
 location            = azurerm_resource_group.hpcc.location
 resource_group_name = azurerm_resource_group.hpcc.name

 ip_configuration {
   name                          = "thor-Configuration"
   subnet_id                     = azurerm_subnet.hpcc.id
   private_ip_address_allocation = "Dynamic"
   public_ip_address_id          = element(azurerm_public_ip.hpcc-thor.*.id, count.index)
 }
}

resource "azurerm_virtual_machine" "hpcc-thor" {
 count                 = "${var.thornodes}"
 name                  = "${var.prefix_cluster_name}-thor-${count.index}"
 location              = azurerm_resource_group.hpcc.location
 availability_set_id   = azurerm_availability_set.avset.id
 resource_group_name   = azurerm_resource_group.hpcc.name
 network_interface_ids = [element(azurerm_network_interface.hpcc-thor.*.id, count.index)]
 vm_size               = "${var.vm_size}"

 delete_os_disk_on_termination = "${var.delete_os_disk_on_termination}"
 delete_data_disks_on_termination = "${var.delete_data_disks_on_termination}"

 storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
 }

 storage_os_disk {
    name              = "${var.prefix_cluster_name}-thor-osdisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = "${var.osdisksize}"
 }

 storage_data_disk {
    name              = "${var.prefix_cluster_name}-thor-datadisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.thordisksize}"
 }

 os_profile {
   computer_name  = "hpcc-thor"
   admin_username = "${var.admin_username}"
   admin_password = "${var.admin_password}"
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.hpcc-thor.*.ip_address, count.index)}"
 }

 # It's easy to transfer files or templates using Terraform.
 provisioner "file" {
    source      = "files/centos_install_hpcc.sh"
    destination = "/home/${var.admin_username}/install_hpcc.sh"
 }

 # It's easy to transfer files or templates using Terraform.
 provisioner "file" {
    source      = "files/mkFileSystemAndMountDevice.pl"
    destination = "/home/${var.admin_username}/mkFileSystemAndMountDevice.pl"
 }

 # This shell script starts our Apache server and prepares the demo environment.
 provisioner "remote-exec" {
    inline = [
      "#Setup logging and having everything goto /home/adminuser/user-data.log",
      "echo ${var.admin_password} | sudo -S ls -l",
      "exec 3>&1 4>&2",
      "trap 'exec 2>&4 1>&3' 0 1 2 3",
      "exec 1>/home/adminuser/user-data.log 2>&1",
      "echo Add execution permissions to *.sh and *.pl",
      "chmod +x /home/${var.admin_username}/*.sh",
      "chmod +x /home/${var.admin_username}/*.pl",
      "cp -v /tmp/terraform*.sh /home/${var.admin_username}",
      "echo mkFileSystemAndMountDevice.pl",
      "/home/${var.admin_username}/mkFileSystemAndMountDevice.pl ${var.admin_password}",
      "echo DEBUG: install hpcc and all its dependences",
      "echo ${var.admin_password} | sudo -S /home/${var.admin_username}/install_hpcc.sh ${var.platform} ${var.admin_password}",
      "exit"
    ]
 }
}

resource "azurerm_public_ip" "hpcc-roxie" {
 count                        = "${var.roxienodes}"
 name                         = "roxie-public-ip-${count.index}"
 location                     = azurerm_resource_group.hpcc.location
 resource_group_name          = azurerm_resource_group.hpcc.name
 allocation_method            = "Static"
}

resource "azurerm_network_interface" "hpcc-roxie" {
  count               = "${var.roxienodes}"
  name                = "roxie-ni-${count.index}"
  location            = azurerm_resource_group.hpcc.location
  resource_group_name = azurerm_resource_group.hpcc.name

  ip_configuration {
     name                          = "roxie-Configuration"
     subnet_id                     = azurerm_subnet.hpcc.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = element(azurerm_public_ip.hpcc-roxie.*.id, count.index)
  }
}

resource "azurerm_virtual_machine" "hpcc-roxie" {
 count                 = "${var.roxienodes}"
 name                  = "${var.prefix_cluster_name}-roxie-${count.index}"
 location              = azurerm_resource_group.hpcc.location
 availability_set_id   = azurerm_availability_set.avset.id
 resource_group_name   = azurerm_resource_group.hpcc.name
 network_interface_ids = [element(azurerm_network_interface.hpcc-roxie.*.id, count.index)]
 vm_size               = "${var.vm_size}"

 delete_os_disk_on_termination = "${var.delete_os_disk_on_termination}"
 delete_data_disks_on_termination = "${var.delete_data_disks_on_termination}"

 storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
 }

 storage_os_disk {
   name              = "${var.prefix_cluster_name}-roxie-osdisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = "${var.osdisksize}"
 }

 storage_data_disk {
    name              = "${var.prefix_cluster_name}-roxie-datadisk"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.roxiedisksize}"
 }

 os_profile {
   computer_name  = "hpcc-roxie"
   admin_username = "${var.admin_username}"
   admin_password = "${var.admin_password}"
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.hpcc-roxie.*.ip_address, count.index)}"
 }

 # It's easy to transfer files or templates using Terraform.
 provisioner "file" {
    source      = "files/centos_install_hpcc.sh"
    destination = "/home/${var.admin_username}/install_hpcc.sh"
 }

 # It's easy to transfer files or templates using Terraform.
 provisioner "file" {
    source      = "files/mkFileSystemAndMountDevice.pl"
    destination = "/home/${var.admin_username}/mkFileSystemAndMountDevice.pl"
 }

 # This shell script starts our Apache server and prepares the demo environment.
 provisioner "remote-exec" {
    inline = [
      "#Setup logging and having everything goto /home/adminuser/user-data.log",
      "echo ${var.admin_password} | sudo -S ls -l",
      "exec 3>&1 4>&2",
      "trap 'exec 2>&4 1>&3' 0 1 2 3",
      "exec 1>/home/adminuser/user-data.log 2>&1",
      "echo Add execution permissions to *.sh and *.pl",
      "chmod +x /home/${var.admin_username}/*.sh",
      "chmod +x /home/${var.admin_username}/*.pl",
      "cp -v /tmp/terraform*.sh /home/${var.admin_username}",
      "echo mkFileSystemAndMountDevice.pl",
      "/home/${var.admin_username}/mkFileSystemAndMountDevice.pl ${var.admin_password}",
      "echo DEBUG: install hpcc and all its dependences",
      "echo ${var.admin_password} | sudo -S /home/${var.admin_username}/install_hpcc.sh ${var.platform} ${var.admin_password}",
      "exit"
    ]
 }
}

resource "azurerm_public_ip" "hpcc-master" {
 name                         = "master-public-ip"
 location                     = azurerm_resource_group.hpcc.location
 resource_group_name          = azurerm_resource_group.hpcc.name
 allocation_method            = "Static"
}

resource "azurerm_network_interface" "hpcc-master" {
  name                      = "${var.prefix_cluster_name}-master"
  location                  = azurerm_resource_group.hpcc.location
  resource_group_name       = azurerm_resource_group.hpcc.name

  ip_configuration {
    name                          = "${var.prefix_cluster_name}-ipconfig"
    subnet_id                     = azurerm_subnet.hpcc.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hpcc-master.id}"
  }
}

resource "azurerm_virtual_machine" "hpcc-master" {
 name                  = "${var.prefix_cluster_name}-master"
 location              = azurerm_resource_group.hpcc.location
 availability_set_id   = azurerm_availability_set.avset.id
 resource_group_name   = azurerm_resource_group.hpcc.name
 network_interface_ids = ["${azurerm_network_interface.hpcc-master.id}"]
 vm_size               = "${var.vm_size}"
 depends_on            = [azurerm_virtual_machine.hpcc-thor,azurerm_virtual_machine.hpcc-roxie]

 delete_os_disk_on_termination = "${var.delete_os_disk_on_termination}"
 delete_data_disks_on_termination = "${var.delete_data_disks_on_termination}"

 storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
 }

 storage_os_disk {
    name              = "${var.prefix_cluster_name}-master-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = "${var.osdisksize}"
 }
 
 storage_data_disk {
    name              = "${var.prefix_cluster_name}-master-datadisk"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.supportdisksize}"
 }

 os_profile {
   computer_name  = "hpcc-master"
   admin_username = "${var.admin_username}"
   admin_password = "${var.admin_password}"
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 connection {
   type     = "ssh"
   user     = "${var.admin_username}"
   password = "${var.admin_password}"
   host     = "${azurerm_public_ip.hpcc-master.ip_address}"
 }

 # Copy centos_install_hpcc.sh to install_hpcc.sh of the user's home directory.
 provisioner "file" {
    source      = "files/centos_install_hpcc.sh"
    destination = "/home/${var.admin_username}/install_hpcc.sh"
 }

 # Copy my_envgen.sh to my_envgen.sh of the user's home directory.
 provisioner "file" {
    source      = "files/my_envgen.sh"
    destination = "/home/${var.admin_username}/my_envgen.sh"
 }

 # Copy start_hpcc.sh to start_hpcc.sh of the user's home directory.
 provisioner "file" {
    source      = "files/start_hpcc.sh"
    destination = "/home/${var.admin_username}/start_hpcc.sh"
 }

 # It's easy to transfer files or templates using Terraform.
 provisioner "file" {
    source      = "files/mkFileSystemAndMountDevice.pl"
    destination = "/home/${var.admin_username}/mkFileSystemAndMountDevice.pl"
 }

 # This shell script starts our Apache server and prepares the demo environment.
 provisioner "remote-exec" {
    inline = [
      "#Setup logging and having everything goto /home/adminuser/user-data.log",
      "echo ${var.admin_password} | sudo -S ls -l",
      "exec 3>&1 4>&2",
      "trap 'exec 2>&4 1>&3' 0 1 2 3",
      "exec 1>/home/adminuser/user-data.log 2>&1",
      "echo Add execution permissions to *.sh and *.pl",
      "chmod +x /home/${var.admin_username}/*.sh",
      "chmod +x /home/${var.admin_username}/*.pl",
      "cp -v /tmp/terraform*.sh /home/${var.admin_username}",
      "echo mkFileSystemAndMountDevice.pl",
      "/home/${var.admin_username}/mkFileSystemAndMountDevice.pl ${var.admin_password}",
      "echo sudo /home/${var.admin_username}/install_hpcc.sh ${var.platform} ${var.admin_password}",
      "echo ${var.admin_password} | sudo -S /home/${var.admin_username}/install_hpcc.sh ${var.platform} ${var.admin_password}",
      "echo sudo /home/${var.admin_username}/my_envgen.sh ${var.thornodes} ${var.roxienodes} ${azurerm_network_interface.hpcc-master.private_ip_address} ${join(var.a_space,azurerm_network_interface.hpcc-roxie.*.private_ip_address)} ${join(var.a_space,azurerm_network_interface.hpcc-thor.*.private_ip_address)}",
      "echo ${var.admin_password} | sudo -S /home/${var.admin_username}/my_envgen.sh ${var.thornodes} ${var.roxienodes} ${var.slavesPerNode} ${azurerm_network_interface.hpcc-master.private_ip_address} ${join(var.a_space,azurerm_network_interface.hpcc-roxie.*.private_ip_address)} ${join(var.a_space,azurerm_network_interface.hpcc-thor.*.private_ip_address)}",
      "echo sudo /home/${var.admin_username}/start_hpcc.sh",
      "echo ${var.admin_password} | sudo -S /home/${var.admin_username}/start_hpcc.sh",
    ]
 }
}

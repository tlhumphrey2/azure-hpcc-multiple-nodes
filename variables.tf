##############################################################################
# Variables File
# 
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "vm_size" {
  description = "The size of the vm used for all cluster VMs."
  default     = "Standard_DS2_v2"
}

variable "prefix_cluster_name" {
  description = "This cluster name prefix will be included in the name of some resources."
  default     = "hpcc"
}

variable "platform" {
  description = "hpcc platform to install"
  default     = "https://d2wulyp08c6njk.cloudfront.net/releases/CE-Candidate-7.6.36/bin/platform/hpccsystems-platform-community_7.6.36-1xenial_amd64.deb"
}

variable "resource_group_name" {
  description = "Specifies the name of the resource group."
  default     = "tlh-hpcc-rg"
}

variable "thornodes" {
  description = "Specifies the size of the system disk (in GB)."
  default     = "2"
}

variable "slavesPerNode" {
  description = "Specifies the number of slaves on a given vm or instance."
  default     = "1"
}

variable "roxienodes" {
  description = "Specifies the size of the system disk (in GB)."
  default     = "0"
}

variable "delete_os_disk_on_termination" {
  description = "true means os disk is deleted when vm is terminated."
  default     = "true"
}

variable "delete_data_disks_on_termination" {
  description = "true means data disk is deleted when vm is terminated."
  default     = "true"
}

variable "osdisksize" {
  description = "Specifies the size of the system disk (in GB)."
  default     = "30"
}

variable "supportdisksize" {
  description = "Specifies the size of the system disk (in GB)."
  default     = "30"
}

variable "thordisksize" {
  description = "Specifies the size of the system disk (in GB)."
  default     = "30"
}

variable "roxiedisksize" {
  description = "Specifies the size of the system disk (in GB)."
  default     = "30"
}

variable "image_publisher" {
  description = "Name of the publisher of the image (az vm image list)"
  default     = "openLogic"
}

variable "image_offer" {
  description = "Name of the offer (az vm image list)"
  default     = "CentOS"
}

variable "image_sku" {
  description = "Image SKU to apply (az vm image list)"
  default     = "7.3"
}

variable "image_version" {
  description = "Version of the image to apply (az vm image list)"
  default     = "latest"
}

variable "admin_username" {
  description = "Administrator user name"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Administrator password"
  default     = "password"
}

variable "a_space" {
  description = "Single space."
  default     = " "
}

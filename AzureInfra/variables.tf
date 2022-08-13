variable "dbvmstaticip" {
  type        = string
  description = "static ip for database VM"
}

variable "mediawikirg" {
  type        = string
  description = "this is the resource group"
}

variable "region" {
  type        = string
  description = "this is the region to deploy resources"
}

variable "client_secret" {
  type        = string
  description = "Service principle client secret"
}

variable "vmsku" {
  type        = string
  description = "Virtual machine sku"
  default     = "Standard_D4s_v5"
}

variable "linux_admin_username" {
  type        = string
  description = "linux username"  
}

variable "mediavnetcidr" {
type = string
description = "This is the mediawiki vnet cidr"
}

variable "mediavnet" {
type = string
description = "This is the mediawiki vnet name"
}

variable "mediaappsubnet" {
type = string
description = "This is subnet name for application servers"
}

variable "mediaappsubnetcidr" {
type = string
description = "This is subnet cidr for application servers"
}

variable "mediadbsubnet" {
type = string
description = "This is subnet name for database serves "
}

variable "mediadbsubnetcidr" {
type = string
description = "This is subnet cidr for database server"
}

variable "lbpublicipname" {
type = string
description = "This is the Load balancer public Ip Name"
}

variable "mediaapplbname" {
type = string
description = "This is the Load balancer Name"
}

variable "lbappbpname" {
type = string
description = "This is the Load balancer backend pool name"
}
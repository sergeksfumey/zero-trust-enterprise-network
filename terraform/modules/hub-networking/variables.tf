variable "hub_vnet_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "hub_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "firewall_subnet_prefix" {
  type    = list(string)
  default = ["10.0.0.0/26"]
}

variable "management_subnet_prefix" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "jumpbox_subnet_prefix" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}

variable "corp_ip_ranges" {
  description = "Corporate IP ranges for management access"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

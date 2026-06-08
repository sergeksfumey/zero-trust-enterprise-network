variable "spoke_vnet_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "hub_resource_group_name" {
  type = string
}

variable "hub_vnet_name" {
  type = string
}

variable "location" {
  type = string
}

variable "spoke_address_space" {
  type    = list(string)
  default = ["10.1.0.0/16"]
}

variable "workload_subnet_prefix" {
  type    = list(string)
  default = ["10.1.0.0/24"]
}

variable "data_subnet_prefix" {
  type    = list(string)
  default = ["10.1.1.0/24"]
}

variable "hub_vnet_id" {
  type = string
}

variable "hub_address_space" {
  type = list(string)
}

variable "jumpbox_subnet_prefix" {
  type = list(string)
}

variable "firewall_private_ip" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

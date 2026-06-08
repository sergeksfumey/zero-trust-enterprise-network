variable "hub_resource_group_name" {
  type    = string
  default = "rg-zero-trust-hub-prod"
}

variable "spoke_resource_group_name" {
  type    = string
  default = "rg-zero-trust-spoke-prod"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "corp_ip_ranges" {
  description = "Corporate IP ranges for management access"
  type        = list(string)
}

variable "break_glass_group_id" {
  description = "Entra ID group object ID for break-glass accounts"
  type        = string
}

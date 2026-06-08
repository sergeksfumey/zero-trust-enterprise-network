# =============================================================================
# Environment: Production
# Description: Zero Trust Enterprise Network -- Azure Security Control Plane
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "stgtfstateprod001"
    container_name       = "tfstate"
    key                  = "zero-trust-network/prod.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

resource "azurerm_resource_group" "hub" {
  name     = var.hub_resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = var.spoke_resource_group_name
  location = var.location
  tags     = local.tags
}

module "monitoring" {
  source              = "../../modules/monitoring"
  workspace_name      = "law-zero-trust-prod"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  tags                = local.tags
}

module "hub_networking" {
  source                   = "../../modules/hub-networking"
  hub_vnet_name            = "vnet-hub-prod"
  resource_group_name      = azurerm_resource_group.hub.name
  location                 = var.location
  hub_address_space        = ["10.0.0.0/16"]
  firewall_subnet_prefix   = ["10.0.0.0/26"]
  management_subnet_prefix = ["10.0.1.0/24"]
  jumpbox_subnet_prefix    = ["10.0.2.0/24"]
  corp_ip_ranges           = var.corp_ip_ranges
  tags                     = local.tags
}

module "azure_firewall" {
  source                     = "../../modules/azure-firewall"
  resource_group_name        = azurerm_resource_group.hub.name
  location                   = var.location
  firewall_subnet_id         = module.hub_networking.firewall_subnet_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = local.tags
}

module "spoke_networking" {
  source                  = "../../modules/spoke-networking"
  spoke_vnet_name         = "vnet-spoke-prod"
  resource_group_name     = azurerm_resource_group.spoke.name
  hub_resource_group_name = azurerm_resource_group.hub.name
  hub_vnet_name           = "vnet-hub-prod"
  location                = var.location
  spoke_address_space     = ["10.1.0.0/16"]
  workload_subnet_prefix  = ["10.1.0.0/24"]
  data_subnet_prefix      = ["10.1.1.0/24"]
  hub_vnet_id             = module.hub_networking.hub_vnet_id
  hub_address_space       = ["10.0.0.0/16"]
  jumpbox_subnet_prefix   = ["10.0.2.0/24"]
  firewall_private_ip     = module.azure_firewall.firewall_private_ip
  tags                    = local.tags
}

module "conditional_access" {
  source               = "../../modules/conditional-access"
  policy_state         = "enabledForReportingButNotEnforced"
  break_glass_group_id = var.break_glass_group_id
}

locals {
  tags = {
    environment = "prod"
    project     = "zero-trust-network"
    compliance  = "nist-800-207-cis-v8-iso27001"
    owner       = "security-architecture-team"
  }
}

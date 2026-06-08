# =============================================================================
# Module: azure-firewall
# Description: Azure Firewall Premium with IDPS and centralised policy
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-azure-firewall"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "main" {
  name                = "afwp-zero-trust"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"

  intrusion_detection {
    mode = "Deny"
  }

  dns {
    proxy_enabled = true
  }

  tags = var.tags
}

# Application Rule Collection -- Allowed outbound FQDNs
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "rcg-zero-trust-policy"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  application_rule_collection {
    name     = "arc-allowed-outbound"
    priority = 100
    action   = "Allow"

    rule {
      name = "Allow-WindowsUpdate"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.0.0.0/8"]
      destination_fqdns = [
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "*.microsoft.com"
      ]
    }

    rule {
      name = "Allow-AzureServices"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.0.0.0/8"]
      destination_fqdns = [
        "*.azure.com",
        "*.azure.net",
        "*.microsoft.com",
        "*.microsoftonline.com"
      ]
    }
  }

  network_rule_collection {
    name     = "nrc-infrastructure"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "Allow-DNS"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "Allow-NTP"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }
}

resource "azurerm_firewall" "main" {
  name                = "afw-zero-trust"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.main.id

  ip_configuration {
    name                 = "pip-config"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = var.tags
}

# Diagnostic settings -- all logs to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-firewall"
  target_resource_id         = azurerm_firewall.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }
  enabled_log { category = "AZFWIdpsSignature" }
  enabled_log { category = "AZFWThreatIntel" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

output "firewall_private_ip" {
  value = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  value = azurerm_public_ip.firewall.ip_address
}

output "firewall_id" {
  value = azurerm_firewall.main.id
}

# =============================================================================
# Module: monitoring
# Description: Log Analytics Workspace and Sentinel for Zero Trust monitoring
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = var.tags
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "main" {
  workspace_id = azurerm_log_analytics_workspace.main.id
}

# Sentinel -- PIM activation monitoring rule
resource "azurerm_sentinel_alert_rule_scheduled" "pim_activation" {
  name                       = "rule-pim-activation-outside-hours"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name               = "PIM Role Activation Outside Business Hours"
  severity                   = "Medium"
  enabled                    = true

  query = <<-KQL
    AuditLogs
    | where TimeGenerated > ago(1d)
    | where OperationName contains "Add eligible member to role"
       or OperationName contains "Add member to role (PIM activation)"
    | extend
        ActivatedBy = tostring(InitiatedBy.user.userPrincipalName),
        Role        = tostring(TargetResources[0].displayName),
        Hour        = hourofday(TimeGenerated)
    | where Hour < 7 or Hour > 19
    | project TimeGenerated, ActivatedBy, Role, Hour
  KQL

  query_frequency   = "PT1H"
  query_period      = "P1D"
  trigger_operator  = "GreaterThan"
  trigger_threshold = 0
  tactics           = ["PrivilegeEscalation"]
  techniques        = ["T1078.004"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled                 = true
      lookback_duration       = "PT5H"
      reopen_closed_incidents = false
      entity_matching_method  = "Selected"
      group_by_entities       = ["Account"]
    }
  }
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "workspace_resource_id" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}

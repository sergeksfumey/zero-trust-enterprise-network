# =============================================================================
# Module: conditional-access
# Description: Zero Trust Conditional Access policies via Entra ID
# =============================================================================

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

# Policy 1: Require MFA for All Users
resource "azuread_conditional_access_policy" "require_mfa" {
  display_name = "CA-ZT-001: Require MFA -- All Users"
  state        = var.policy_state

  conditions {
    users {
      included_users  = ["All"]
      excluded_groups = [var.break_glass_group_id]
    }
    applications {
      included_applications = ["All"]
    }
    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# Policy 2: Block Legacy Authentication
resource "azuread_conditional_access_policy" "block_legacy_auth" {
  display_name = "CA-ZT-002: Block Legacy Authentication"
  state        = var.policy_state

  conditions {
    users {
      included_users = ["All"]
    }
    applications {
      included_applications = ["All"]
    }
    client_app_types = ["exchangeActiveSync", "other"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# Policy 3: Require Compliant Device for Privileged Access
resource "azuread_conditional_access_policy" "require_compliant_device_admin" {
  display_name = "CA-ZT-003: Require Compliant Device -- Privileged Access"
  state        = var.policy_state

  conditions {
    users {
      included_roles = [
        "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
        "194ae4cb-b126-40b2-bd5b-6091b380977d", # Security Administrator
        "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"  # SharePoint Administrator
      ]
    }
    applications {
      included_applications = ["All"]
    }
    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "compliantDevice"]
  }
}

# Policy 4: High Risk Sign-In Response
resource "azuread_conditional_access_policy" "high_risk_signin" {
  display_name = "CA-ZT-004: High Risk Sign-In -- Force Password Change"
  state        = var.policy_state

  conditions {
    users {
      included_users  = ["All"]
      excluded_groups = [var.break_glass_group_id]
    }
    applications {
      included_applications = ["All"]
    }
    client_app_types    = ["all"]
    sign_in_risk_levels = ["high"]
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "passwordChange"]
  }
}

<#
.SYNOPSIS
    Activates a PIM-eligible role assignment for the current user.

.DESCRIPTION
    Activates a PIM-eligible Azure AD role via Microsoft Graph API.
    Requires written justification for audit trail.
    All activations logged to Entra ID audit log and forwarded to Sentinel.

.PARAMETER RoleName
    Display name of the role to activate (e.g. "Global Administrator").

.PARAMETER DurationHours
    Activation duration in hours (max 4 for high-privilege roles). Default: 1.

.PARAMETER Justification
    Written business justification for activation (required for audit trail).

.NOTES
    Requires: Microsoft.Graph PowerShell module
    PCI DSS 7.1: Least-privilege access -- JIT elevation only
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$RoleName,
    [ValidateRange(1, 4)][int]$DurationHours = 1,
    [Parameter(Mandatory)][string]$Justification
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
}

try {
    Write-Log "=== PIM ROLE ACTIVATION ==="
    Write-Log "Role: $RoleName | Duration: $DurationHours hours"
    Write-Log "Justification: $Justification"

    Import-Module Microsoft.Graph.Identity.Governance -ErrorAction Stop
    Connect-MgGraph -Scopes "RoleEligibilitySchedule.Read.Directory", "RoleAssignmentSchedule.ReadWrite.Directory" -NoWelcome

    $currentUser = (Get-MgContext).Account
    Write-Log "Activating for: $currentUser"

    # Get role definition
    $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$RoleName'"
    if (-not $roleDefinition) {
        throw "Role not found: $RoleName"
    }

    # Get eligible assignment
    $eligibleAssignment = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "roleDefinitionId eq '$($roleDefinition.Id)'" |
        Where-Object { $_.Principal.AdditionalProperties.userPrincipalName -eq $currentUser }

    if (-not $eligibleAssignment) {
        throw "No eligible assignment found for role: $RoleName"
    }

    # Activate role
    $params = @{
        Action           = "selfActivate"
        PrincipalId      = $eligibleAssignment.PrincipalId
        RoleDefinitionId = $roleDefinition.Id
        DirectoryScopeId = "/"
        Justification    = $Justification
        ScheduleInfo     = @{
            StartDateTime = (Get-Date).ToUniversalTime()
            Expiration    = @{
                Type     = "AfterDuration"
                Duration = "PT${DurationHours}H"
            }
        }
    }

    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params

    Write-Log "Role '$RoleName' activated for $DurationHours hour(s)"
    Write-Log "Activation will expire at: $((Get-Date).AddHours($DurationHours).ToString('yyyy-MM-dd HH:mm:ss')) UTC"
    Write-Log "All activation events logged to Entra ID audit log and Microsoft Sentinel"

} catch {
    Write-Log "PIM activation failed: $_" -Level "ERROR"
    throw
}

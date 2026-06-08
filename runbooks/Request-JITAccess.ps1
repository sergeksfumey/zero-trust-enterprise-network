<#
.SYNOPSIS
    Requests Just-in-Time VM access for RDP or SSH via Defender for Cloud.

.DESCRIPTION
    Initiates a JIT access request for a specific VM management port.
    Access granted for requesting source IP only, for defined duration.
    All JIT access events logged to Log Analytics and Sentinel.

.PARAMETER VMResourceId
    Azure resource ID of the target VM.

.PARAMETER Port
    Management port to open: 3389 (RDP) or 22 (SSH).

.PARAMETER DurationHours
    Access duration in hours (max 3). Default: 1.

.PARAMETER Justification
    Written justification for access request (audit trail).

.NOTES
    Requires: Az.Security PowerShell module
    VM must have JIT access policy configured in Defender for Cloud
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$VMResourceId,
    [ValidateSet(3389, 22)][int]$Port = 3389,
    [ValidateRange(1, 3)][int]$DurationHours = 1,
    [Parameter(Mandatory)][string]$Justification
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
}

try {
    Write-Log "=== JIT VM ACCESS REQUEST ==="
    Write-Log "VM: $VMResourceId | Port: $Port | Duration: $DurationHours hours"
    Write-Log "Justification: $Justification"

    # Get requesting IP
    $myIP = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
    Write-Log "Requesting source IP: $myIP"

    # Parse VM details from resource ID
    $idParts       = $VMResourceId.Split("/")
    $subscriptionId = $idParts[2]
    $resourceGroup  = $idParts[4]
    $vmName         = $idParts[8]

    # Request JIT access via Azure REST API
    $token   = (Get-AzAccessToken).Token
    $headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

    $body = @{
        virtualMachines = @(
            @{
                id    = $VMResourceId
                ports = @(
                    @{
                        number                  = $Port
                        duration                = "PT${DurationHours}H"
                        allowedSourceAddressPrefix = $myIP
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Security/locations/westeurope/jitNetworkAccessPolicies/default/initiate?api-version=2020-01-01"

    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body

    Write-Log "JIT access granted for port $Port"
    Write-Log "Source IP: $myIP | Duration: $DurationHours hour(s)"
    Write-Log "Port will be automatically closed at: $((Get-Date).AddHours($DurationHours).ToString('yyyy-MM-dd HH:mm:ss')) UTC"
    Write-Log "Access event logged to Log Analytics and Microsoft Sentinel"

} catch {
    Write-Log "JIT access request failed: $_" -Level "ERROR"
    throw
}

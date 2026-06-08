# Architecture Notes -- Zero Trust Enterprise Network

## Network Address Design

Hub VNet: 10.0.0.0/16
- AzureFirewallSubnet: 10.0.0.0/26 (required name, /26 minimum)
- ManagementSubnet: 10.0.1.0/24
- JumpboxSubnet: 10.0.2.0/24

Spoke VNet: 10.1.0.0/16
- WorkloadSubnet: 10.1.0.0/24
- DataSubnet: 10.1.1.0/24

## Traffic Flow Design

Internet inbound:
Internet --> Azure Firewall (public IP) --> Application rules --> Workload subnet

Admin access:
Corp IP --> Management Subnet NSG --> Jumpbox --> JIT request --> Workload VM (port opened temporarily)

Spoke to spoke:
Spoke A --> UDR --> Azure Firewall --> Firewall policy evaluation --> Spoke B

Outbound internet:
Workload VM --> UDR --> Azure Firewall --> Application rules (FQDN allowlist) --> Internet

## PIM Configuration

Eligible roles (no permanent active assignments):
- Global Administrator: max 4h activation, requires approval, requires justification
- Security Administrator: max 4h activation, requires justification
- Contributor: max 8h activation, self-approval, requires justification
- Reader: max 8h activation, self-approval

Alert configuration:
- PIM activation outside business hours (07:00-19:00 UTC): Sentinel Medium alert
- Global Administrator activation: Sentinel High alert (always)
- Activation from new location: Sentinel Medium alert

## Conditional Access Design

Policy state during rollout:
1. enabledForReportingButNotEnforced (report-only) -- 30 days
2. enabled -- after sign-in log review and false positive resolution

Break-glass accounts:
- Two cloud-only accounts excluded from all CA policies
- Excluded via security group (GRP-BreakGlass)
- Any sign-in triggers P1 Sentinel alert

Named locations:
- Corporate office IP ranges (trusted)
- Remote access VPN exit IPs (trusted)
- All other locations: subject to MFA + risk evaluation

## JIT VM Access Configuration

Default policy per VM:
- RDP (3389): max 3 hours, requires justification, source IP locked to requester
- SSH (22): max 3 hours, requires justification, source IP locked to requester
- WinRM (5985/5986): disabled (not included in JIT policy)

JIT request workflow:
1. Administrator activates PIM role (Contributor minimum)
2. Administrator submits JIT request with justification
3. JIT approval: self-approval for standard VMs, peer approval for production
4. Port opened: requesting source IP only, for requested duration
5. Automatic closure: NSG rule removed after expiry, no manual action required

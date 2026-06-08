# Compliance Control Mapping

## NIST SP 800-207 Zero Trust Architecture

| Tenant | Description | Implementation |
|---|---|---|
| 1 -- Verify Explicitly | All resources authenticate and authorise | Conditional Access evaluates every request |
| 2 -- Least Privilege | Limit access with JIT and context-aware policies | PIM JIT · time-bound roles · JIT VM access |
| 3 -- Assume Breach | Minimise blast radius, segment access, verify E2E encryption | Hub-and-spoke segmentation · NSG micro-segmentation · Sentinel SIEM |

## CIS Controls v8

| Control | Description | Implementation |
|---|---|---|
| 4.1 | Establish secure configuration | Azure Policy baseline enforcement |
| 5.4 | Restrict admin privileges | PIM zero standing privileges |
| 6.3 | Require MFA for admin accounts | CA-ZT-003 -- Compliant device + MFA |
| 6.5 | Require MFA for remote network access | CA-ZT-001 -- MFA all users |
| 8.2 | Collect audit logs | Log Analytics -- all diagnostic settings |
| 12.2 | Establish network infrastructure | Hub-and-spoke · Azure Firewall |
| 12.3 | Securely manage network infrastructure | Terraform IaC · Azure Policy |
| 13.3 | Deploy network monitoring | NSG flow logs · Firewall IDPS · Sentinel |

## ISO 27001:2022

| Control | Description | Implementation |
|---|---|---|
| A.8.2 | Privileged access rights | PIM JIT -- no standing privilege |
| A.8.3 | Information access restriction | Conditional Access · RBAC scoping |
| A.8.18 | Use of privileged utility programs | JIT VM Access -- port governance |
| A.8.20 | Networks security | Hub-and-spoke · Azure Firewall · NSGs |
| A.8.22 | Segregation of networks | Subnet isolation · NSG micro-segmentation |
| A.8.15 | Logging | Log Analytics centralised telemetry |
| A.8.16 | Monitoring activities | Sentinel SIEM · analytics rules |

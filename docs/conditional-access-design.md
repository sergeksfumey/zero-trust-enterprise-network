# Conditional Access Design Guide

## Policy Naming Convention

CA-ZT-XXX: [Action] -- [Scope]
- CA: Conditional Access
- ZT: Zero Trust namespace
- XXX: Sequential number
- Action: Require, Block, Enforce
- Scope: affected users or apps

## Policy Deployment Order

Deploy in report-only first -- monitor for 30 days before enforcing:

Week 1-2 (Report-only):
1. CA-ZT-001: Require MFA -- All Users
2. CA-ZT-002: Block Legacy Authentication

Week 3-4 (Report-only):
3. CA-ZT-003: Require Compliant Device -- Privileged Access
4. CA-ZT-004: High Risk Sign-In Response

Week 5+ (Enforce):
- Review report-only logs -- identify false positives
- Whitelist known service accounts
- Enable enforcement for CA-ZT-001 and CA-ZT-002 first
- Enable remaining policies sequentially

## Break-Glass Account Procedure

Break-glass accounts (2x cloud-only):
- Excluded from ALL Conditional Access policies via GRP-BreakGlass
- Passwords: 64-character random, stored in physical safe
- MFA: excluded (by design -- emergency access when CA is misconfigured)
- Any sign-in: immediate P1 Sentinel alert with on-call notification
- Review: access logs reviewed monthly, passwords rotated annually

## Legacy Authentication Migration

Before enabling CA-ZT-002 (Block Legacy Auth):
1. Run report-only mode for 30 days
2. Identify applications using legacy auth from sign-in logs:
   KQL: SigninLogs | where ClientAppUsed in ("Exchange ActiveSync", "Other clients") | summarize count() by AppDisplayName, UserPrincipalName
3. Migrate each application to modern auth (OAuth 2.0 / MSAL)
4. Coordinate with application owners before enforcement
5. Enable enforcement only after legacy auth traffic reaches zero

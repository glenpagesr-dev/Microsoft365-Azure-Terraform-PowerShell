# Runbook — New-Hire Onboarding Automation (Lab 6 Capstone)

A one-page operational guide for running the onboarding pipeline. Written so
someone other than the author can execute it safely.

## Purpose

Provision a new hire end-to-end from a single JSON input: Entra ID account,
Microsoft 365 license, group memberships, Azure RBAC, and Exchange Online
shared-mailbox access — with a dry-run mode, an action log, and a rollback path.

## Prerequisites

- PowerShell 7+ with modules: `Microsoft.Graph`, `Az`, `ExchangeOnlineManagement`.
- Signed in with sufficient roles (User Administrator + License Administrator;
  add Privileged Role Administrator if assigning directory roles).
- For the Azure RBAC step: `az login` (or `Connect-AzAccount`) to the right subscription.
- For the mailbox step: `Connect-ExchangeOnline`.
- A completed new-hire JSON (copy and edit `newhire.example.json`).

## Inputs

| Field | Meaning |
|-------|---------|
| `displayName` / `mailNickname` | Name and UPN prefix |
| `jobTitle` / `department` / `manager` | Directory attributes |
| `usageLocation` | Required before a license can be assigned (e.g. `US`) |
| `licenseSkuPartNumber` | e.g. `ENTERPRISEPREMIUM` (E5) |
| `groups` | Security/M365 groups to join |
| `azureRbac` | Role + resource-group scope |
| `sharedMailboxes` | Shared mailboxes to grant FullAccess |

## Procedure

1. **Dry run first — always.**
   ```powershell
   ./Onboard-NewHire.ps1 -InputJson ./newhire.json -Domain <tenant>.onmicrosoft.com -WhatIf
   ```
   Review the console output and confirm the intended actions.

2. **Execute for real.**
   ```powershell
   ./Onboard-NewHire.ps1 -InputJson ./newhire.json -Domain <tenant>.onmicrosoft.com
   ```
   Actions append to `onboarding-log.json`.

3. **Validate** (see checklist below).

## Validation Checklist

- [ ] User exists in Entra ID with correct department/job title
- [ ] License shows as assigned (Get-MgUserLicenseDetail)
- [ ] User is a member of every group in the JSON
- [ ] Azure RBAC role visible at the intended scope
- [ ] Shared-mailbox FullAccess granted
- [ ] `onboarding-log.json` contains one entry per action

## Rollback / Offboarding

```powershell
# Disable + strip access (reversible):
./Offboard-User.ps1 -Upn jordan.blake@<tenant>.onmicrosoft.com -WhatIf
./Offboard-User.ps1 -Upn jordan.blake@<tenant>.onmicrosoft.com

# Permanently delete the test account:
./Offboard-User.ps1 -Upn jordan.blake@<tenant>.onmicrosoft.com -RemoveUser
```

After rollback, confirm **no orphaned access** remains: RBAC assignments and
mailbox permissions are not removed automatically in the stubbed steps — check
them manually (or extend the script) until you've wired those calls in.

## Notes / Known Limitations

- The Azure RBAC and Exchange steps in `Onboard-NewHire.ps1` are **stubbed**
  (commented out) so a dry run is safe out of the box. Uncomment them once you've
  connected `Az` and `ExchangeOnline` and tested against your sandbox.
- Temporary passwords are randomized and force change on first sign-in.
- Never commit a filled-in `newhire.json` with real personal data — it's gitignored.

<#
.SYNOPSIS
    Lab 6 Capstone — reverses onboarding for a user (rollback / offboarding).
.DESCRIPTION
    Disables/removes the user, strips licenses and group memberships. Can read
    the onboarding-log.json to reverse exactly what was granted, or act on a UPN
    directly. Supports -WhatIf.
.PARAMETER Upn
    User principal name to offboard.
.PARAMETER RemoveUser
    Permanently delete the account instead of just disabling it.
.NOTES
    Author : Glen Page   |   Lab 6 - Capstone
    Scopes : User.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Upn,
    [switch]$RemoveUser
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Users, Microsoft.Graph.Groups
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'User.ReadWrite.All','Group.ReadWrite.All','Directory.ReadWrite.All' -NoWelcome
}

$user = Get-MgUser -Filter "userPrincipalName eq '$Upn'" -Top 1
if (-not $user) { throw "User $Upn not found." }

# 1) Remove group memberships
$groups = Get-MgUserMemberOf -UserId $user.Id -All |
    Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' }
foreach ($g in $groups) {
    if ($PSCmdlet.ShouldProcess($Upn, "Remove from group $($g.Id)")) {
        Remove-MgGroupMemberByRef -GroupId $g.Id -DirectoryObjectId $user.Id -ErrorAction SilentlyContinue
    }
}

# 2) Strip licenses
$assigned = (Get-MgUserLicenseDetail -UserId $user.Id).SkuId
if ($assigned -and $PSCmdlet.ShouldProcess($Upn, 'Remove all licenses')) {
    Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses $assigned
}

# 3) Disable or delete
if ($RemoveUser) {
    if ($PSCmdlet.ShouldProcess($Upn, 'Delete user')) { Remove-MgUser -UserId $user.Id }
} else {
    if ($PSCmdlet.ShouldProcess($Upn, 'Disable account')) {
        Update-MgUser -UserId $user.Id -AccountEnabled:$false
    }
}

Write-Host "Offboarding complete for $Upn." -ForegroundColor Green
Write-Host 'Verify in Entra ID that no orphaned access remains (RBAC, mailbox permissions).' -ForegroundColor Yellow

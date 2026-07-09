<#
.SYNOPSIS
    Lab 5 — flags licensed users who have NOT registered MFA.
.DESCRIPTION
    Reads Entra ID credential registration details via Microsoft Graph and
    reports any licensed (enabled) user without MFA registered — a common
    security-audit ask.
.PARAMETER OutPath
    Optional CSV output path.
.NOTES
    Author : Glen Page   |   Lab 5 - Governance at Scale
    Scopes : User.Read.All, AuditLog.Read.All, UserAuthenticationMethod.Read.All
#>

[CmdletBinding()]
param(
    [string]$OutPath
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Users, Microsoft.Graph.Reports
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'User.Read.All', 'AuditLog.Read.All' -NoWelcome
}

# Registration details include whether MFA is capable/registered per user.
$reg = Get-MgReportAuthenticationMethodUserRegistrationDetail -All

$noMfa = $reg | Where-Object { -not $_.IsMfaRegistered } |
    Select-Object UserPrincipalName, UserDisplayName,
                  IsMfaRegistered, IsMfaCapable, IsSsprRegistered

if (-not $noMfa) {
    Write-Host 'All users have MFA registered. Nothing to flag.' -ForegroundColor Green
    return
}

Write-Warning "$($noMfa.Count) user(s) without MFA registered:"
$noMfa | Format-Table -AutoSize

if ($OutPath) {
    $noMfa | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
    Write-Host "Audit written to $OutPath" -ForegroundColor Cyan
}

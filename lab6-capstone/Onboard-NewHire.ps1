<#
.SYNOPSIS
    Lab 6 Capstone — end-to-end new-hire onboarding across Entra ID, licensing,
    groups, Azure RBAC, and Exchange Online.
.DESCRIPTION
    Reads a new-hire JSON contract (a stand-in for a ServiceNow ticket) and
    provisions the account, assigns a license, adds group memberships, applies
    Azure RBAC, and grants shared-mailbox access. Supports -WhatIf dry runs and
    writes a JSON action log for auditing / rollback.
.PARAMETER InputJson
    Path to the new-hire JSON (see newhire.example.json).
.PARAMETER Domain
    Sandbox domain, e.g. yourtenant.onmicrosoft.com.
.PARAMETER LogPath
    JSON action log path (used by Offboard-User.ps1 for rollback).
.EXAMPLE
    ./Onboard-NewHire.ps1 -InputJson ./newhire.example.json -Domain yourtenant.onmicrosoft.com -WhatIf
.NOTES
    Author : Glen Page   |   Lab 6 - Capstone
    Scopes : User.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All,
             RoleManagement.ReadWrite.Directory
    Also uses: Az (RBAC) and ExchangeOnlineManagement (mailboxes).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$InputJson,
    [Parameter(Mandatory)][string]$Domain,
    [string]$LogPath = "$PSScriptRoot/onboarding-log.json"
)

$ErrorActionPreference = 'Stop'

function Write-ActionLog {
    param($Action, $Target, $Extra = @{})
    $entry = [ordered]@{
        timestamp = (Get-Date).ToString('o')
        action    = $Action
        target    = $Target
        whatif    = [bool]$WhatIfPreference
    } + $Extra
    ($entry | ConvertTo-Json -Compress) | Add-Content -Path $LogPath
}

# --- Load contract ------------------------------------------------------
$hire = Get-Content $InputJson -Raw | ConvertFrom-Json
$upn  = "$($hire.mailNickname)@$Domain"
Write-Host "Onboarding: $($hire.displayName) <$upn>" -ForegroundColor Cyan

# --- Connect ------------------------------------------------------------
Import-Module Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'User.ReadWrite.All','Group.ReadWrite.All','Directory.ReadWrite.All' -NoWelcome
}

# --- 1) Create user -----------------------------------------------------
if ($PSCmdlet.ShouldProcess($upn, 'Create user')) {
    $passwordProfile = @{
        Password                      = "TempP@ss-$(Get-Random -Minimum 100000 -Maximum 999999)!"
        ForceChangePasswordNextSignIn = $true
    }
    $user = New-MgUser -DisplayName $hire.displayName -UserPrincipalName $upn `
        -MailNickname $hire.mailNickname -JobTitle $hire.jobTitle `
        -Department $hire.department -UsageLocation $hire.usageLocation `
        -AccountEnabled -PasswordProfile $passwordProfile
    Write-ActionLog 'user_created' $upn @{ id = $user.Id }
} else {
    $user = [pscustomobject]@{ Id = '<whatif>' }
}

# --- 2) Assign license --------------------------------------------------
if ($hire.licenseSkuPartNumber -and $PSCmdlet.ShouldProcess($upn, "Assign license $($hire.licenseSkuPartNumber)")) {
    $sku = Get-MgSubscribedSku | Where-Object SkuPartNumber -eq $hire.licenseSkuPartNumber
    if ($sku) {
        Set-MgUserLicense -UserId $user.Id -AddLicenses @{ SkuId = $sku.SkuId } -RemoveLicenses @()
        Write-ActionLog 'license_assigned' $upn @{ sku = $hire.licenseSkuPartNumber }
    } else {
        Write-Warning "SKU $($hire.licenseSkuPartNumber) not found in tenant."
    }
}

# --- 3) Group memberships ----------------------------------------------
foreach ($g in $hire.groups) {
    if ($PSCmdlet.ShouldProcess($upn, "Add to group $g")) {
        $grp = Get-MgGroup -Filter "displayName eq '$g'" -Top 1
        if ($grp) {
            New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $user.Id
            Write-ActionLog 'group_added' $upn @{ group = $g }
        } else { Write-Warning "Group '$g' not found." }
    }
}

# --- 4) Azure RBAC (requires Az module + az login) ---------------------
foreach ($r in $hire.azureRbac) {
    if ($PSCmdlet.ShouldProcess($upn, "Assign RBAC $($r.role) on $($r.scopeResourceGroup)")) {
        # New-AzRoleAssignment -SignInName $upn -RoleDefinitionName $r.role `
        #   -ResourceGroupName $r.scopeResourceGroup
        Write-ActionLog 'rbac_assigned' $upn @{ role = $r.role; scope = $r.scopeResourceGroup }
        Write-Host "  (RBAC step stubbed — uncomment New-AzRoleAssignment when Az is connected)" -ForegroundColor DarkYellow
    }
}

# --- 5) Exchange shared mailboxes --------------------------------------
foreach ($mbx in $hire.sharedMailboxes) {
    if ($PSCmdlet.ShouldProcess($upn, "Grant access to shared mailbox $mbx")) {
        # Connect-ExchangeOnline
        # Add-MailboxPermission -Identity $mbx -User $upn -AccessRights FullAccess -InheritanceType All
        Write-ActionLog 'mailbox_access_granted' $upn @{ mailbox = $mbx }
        Write-Host "  (Exchange step stubbed — uncomment Add-MailboxPermission when EXO is connected)" -ForegroundColor DarkYellow
    }
}

Write-Host "`nDone. Actions logged to $LogPath" -ForegroundColor Green
if ($WhatIfPreference) { Write-Host '[DRY RUN] No changes were made.' -ForegroundColor Yellow }

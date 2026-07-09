<#
.SYNOPSIS
    Lab 2 — bulk-creates Entra ID users from users.csv and adds them to a group.
.PARAMETER CsvPath
    Path to the input CSV (DisplayName, MailNickname, Department, JobTitle).
.PARAMETER Domain
    Your sandbox domain, e.g. yourtenant.onmicrosoft.com.
.PARAMETER GroupName
    Target security group display name (default: IT-Ops-Test).
.PARAMETER WhatIf
    Preview actions without creating anything.
.NOTES
    Author : Glen Page   |   Lab 2 - Identity Foundations
    Scopes : User.ReadWrite.All, Group.ReadWrite.All
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CsvPath  = "$PSScriptRoot/users.csv",
    [Parameter(Mandatory)][string]$Domain,
    [string]$GroupName = 'IT-Ops-Test'
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Users, Microsoft.Graph.Groups
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Group.ReadWrite.All' -NoWelcome
}

$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -Top 1
if (-not $group) { throw "Group '$GroupName' not found. Create it (portal or Terraform) first." }

Import-Csv $CsvPath | ForEach-Object {
    $upn = "$($_.MailNickname)@$Domain"
    if ($PSCmdlet.ShouldProcess($upn, 'Create user + add to group')) {
        $passwordProfile = @{
            Password                      = "TempP@ss-$(Get-Random -Minimum 1000 -Maximum 9999)!"
            ForceChangePasswordNextSignIn = $true
        }
        $user = New-MgUser -DisplayName $_.DisplayName `
            -UserPrincipalName $upn -MailNickname $_.MailNickname `
            -Department $_.Department -JobTitle $_.JobTitle `
            -AccountEnabled -PasswordProfile $passwordProfile
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
        Write-Host "Created $upn and added to $GroupName" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Lab 1 — verifies the M365 / Azure toolchain is installed and authenticated.
.DESCRIPTION
    Checks for Azure CLI, PowerShell 7, Terraform, and the required PowerShell
    modules, then confirms you can reach both your Azure subscription and your
    Microsoft Entra ID tenant. Run this after completing Lab 1's install steps.
.NOTES
    Author : Glen Page
    Lab    : 1 - Environment & Toolchain Setup
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$results = [System.Collections.Generic.List[object]]::new()

function Add-Check {
    param($Name, $Ok, $Detail)
    $results.Add([pscustomobject]@{ Check = $Name; Status = if ($Ok) { 'PASS' } else { 'FAIL' }; Detail = $Detail })
}

Write-Host "`n=== Lab 1: Toolchain Verification ===`n" -ForegroundColor Cyan

# --- CLIs ---------------------------------------------------------------
try { $v = (az version --output json | ConvertFrom-Json).'azure-cli'; Add-Check 'Azure CLI' $true "v$v" }
catch { Add-Check 'Azure CLI' $false 'Not found — install from https://aka.ms/installazurecli' }

Add-Check 'PowerShell 7+' ($PSVersionTable.PSVersion.Major -ge 7) "v$($PSVersionTable.PSVersion)"

try { $tf = (terraform version -json | ConvertFrom-Json).terraform_version; Add-Check 'Terraform' $true "v$tf" }
catch { Add-Check 'Terraform' $false 'Not found — install from https://developer.hashicorp.com/terraform/install' }

# --- Modules ------------------------------------------------------------
foreach ($m in 'Az', 'Microsoft.Graph', 'ExchangeOnlineManagement') {
    Add-Check "Module: $m" ([bool](Get-Module -ListAvailable -Name $m)) 'Install-Module if missing'
}

# --- Connectivity -------------------------------------------------------
try {
    $acct = az account show --output json | ConvertFrom-Json
    Add-Check 'Azure subscription' $true "$($acct.name) / tenant $($acct.tenantId)"
} catch { Add-Check 'Azure subscription' $false 'Run: az login' }

try {
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'User.Read.All' -NoWelcome }
    $u = Get-MgUser -Top 1
    Add-Check 'Entra ID (Graph)' $true "Reachable — sample user: $($u.UserPrincipalName)"
} catch { Add-Check 'Entra ID (Graph)' $false 'Run: Connect-MgGraph -Scopes "User.Read.All"' }

# --- Report -------------------------------------------------------------
$results | Format-Table -AutoSize
if ($results.Status -contains 'FAIL') {
    Write-Warning 'One or more checks failed. Resolve them before moving to Lab 2.'
    exit 1
}
Write-Host "`nAll checks passed. You're ready for Lab 2." -ForegroundColor Green

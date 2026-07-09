<#
.SYNOPSIS
    Lab 4 — exports Intune managed-device compliance state to CSV.
.DESCRIPTION
    Connects to Microsoft Graph, pulls all managed devices, and writes a
    compliance report you can compare against the Intune portal.
.PARAMETER OutPath
    Destination CSV path.
.NOTES
    Author : Glen Page   |   Lab 4 - Endpoint Management
    Scopes : DeviceManagementManagedDevices.Read.All
#>

[CmdletBinding()]
param(
    [string]$OutPath = "$PSScriptRoot/intune-compliance-report.csv"
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.DeviceManagement
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
}

$devices = Get-MgDeviceManagementManagedDevice -All |
    Select-Object DeviceName, ComplianceState, OperatingSystem, OsVersion,
                  UserPrincipalName, LastSyncDateTime, ManagedDeviceOwnerType

if (-not $devices) {
    Write-Warning 'No managed devices found. Enroll a device (the Lab 3 VM works) first.'
    return
}

$devices | Sort-Object ComplianceState, DeviceName |
    Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8

$summary = $devices | Group-Object ComplianceState |
    Select-Object @{n = 'ComplianceState'; e = { $_.Name } }, Count
Write-Host "`nCompliance summary:" -ForegroundColor Cyan
$summary | Format-Table -AutoSize
Write-Host "Report written to $OutPath" -ForegroundColor Green

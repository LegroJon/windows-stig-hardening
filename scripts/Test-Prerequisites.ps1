<#
.SYNOPSIS
    Windows 11 STIG Assessment Tool - Prerequisites Checker

.DESCRIPTION
    Validates system requirements for running the STIG assessment tool.

.PARAMETER Detailed
    Show detailed system information

.EXAMPLE
    .\Test-Prerequisites.ps1
    Check basic system requirements

.EXAMPLE
    .\Test-Prerequisites.ps1 -Detailed
    Show detailed system information and requirements
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

function Write-CheckResult {
    param(
        [string]$Check,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $status = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status $Check" -ForegroundColor $color
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

Write-Host "`nWindows 11 STIG Assessment Tool - Prerequisites Check" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Check Windows Version
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$isWindows11 = $osInfo.Caption -like "*Windows 11*"
Write-CheckResult "Windows 11 Operating System" $isWindows11 "Detected: $($osInfo.Caption)"

# Check PowerShell Version
$psVersion = $PSVersionTable.PSVersion
$psVersionOk = $psVersion -ge [Version]"5.1"
Write-CheckResult "PowerShell 5.1+" $psVersionOk "Current: $psVersion"

# Check Administrator Privileges
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-CheckResult "Administrator Privileges" $isAdmin "Current user: $($currentUser.Name)"

# Check Execution Policy
$execPolicy = Get-ExecutionPolicy
$execPolicyOk = $execPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")
Write-CheckResult "PowerShell Execution Policy" $execPolicyOk "Current: $execPolicy"

# Check for Pester Module (Optional)
$pesterInstalled = Get-Module -ListAvailable -Name Pester
$hasPester = $null -ne $pesterInstalled
Write-CheckResult "Pester Module (Optional)" $hasPester $(if ($hasPester) { "Version: $($pesterInstalled[0].Version)" } else { "Not installed - required for testing" })

if ($Detailed) {
    Write-Host "`nDetailed System Information" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    Write-Host "OS Version:        " -NoNewline -ForegroundColor White
    Write-Host "$($osInfo.Caption) $($osInfo.Version)" -ForegroundColor Green
    
    Write-Host "OS Architecture:   " -NoNewline -ForegroundColor White
    Write-Host $osInfo.OSArchitecture -ForegroundColor Green
    
    Write-Host "PowerShell:        " -NoNewline -ForegroundColor White
    Write-Host "$($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor Green
    
    Write-Host "Computer Name:     " -NoNewline -ForegroundColor White
    Write-Host $env:COMPUTERNAME -ForegroundColor Green
    
    Write-Host "Domain:            " -NoNewline -ForegroundColor White
    Write-Host $(if ($env:USERDOMAIN -ne $env:COMPUTERNAME) { $env:USERDOMAIN } else { "Workgroup" }) -ForegroundColor Green
    
    Write-Host "Current User:      " -NoNewline -ForegroundColor White
    Write-Host "$env:USERDOMAIN\$env:USERNAME" -ForegroundColor Green
    
    # Check available disk space
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    Write-Host "Free Disk Space:   " -NoNewline -ForegroundColor White
    Write-Host "$freeSpaceGB GB" -ForegroundColor Green
}

# Overall Status
$allChecks = @($isWindows11, $psVersionOk, $isAdmin, $execPolicyOk)
$passedChecks = ($allChecks | Where-Object { $_ }).Count
$totalChecks = $allChecks.Count

Write-Host "`nOverall Status" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

if ($passedChecks -eq $totalChecks) {
    Write-Host "[PASS] All prerequisites met! Ready to run STIG assessment." -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAIL] $($totalChecks - $passedChecks) of $totalChecks checks failed." -ForegroundColor Red
    Write-Host "Please resolve the issues above before running the assessment." -ForegroundColor Yellow
    exit 1
}

<#
.SYNOPSIS
    Installs and configures testing tools for the Windows 11 STIG Assessment Tool

.DESCRIPTION
    This script installs the required PowerShell modules for testing, code analysis,
    and build automation. Run this once to set up the development environment.

.PARAMETER Force
    Force reinstallation of modules even if they exist

.EXAMPLE
    .\Install-TestingTools.ps1
    Install all required testing tools

.EXAMPLE
    .\Install-TestingTools.ps1 -Force
    Force reinstall all testing tools
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

function Write-ToolStatus {
    param(
        [string]$Tool,
        [bool]$Success,
        [string]$Version = "",
        [string]$Details = ""
    )
    
    $status = if ($Success) { "[INSTALLED]" } else { "[FAILED]" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "$status $Tool" -ForegroundColor $color
    if ($Version) {
        Write-Host "   Version: $Version" -ForegroundColor Gray
    }
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

Write-Host "`nWindows 11 STIG Assessment Tool - Testing Tools Installation" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# Check if running as administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[WARNING] Not running as administrator. Some installations may fail." -ForegroundColor Yellow
    Write-Host "Consider running as administrator for best results.`n" -ForegroundColor Yellow
}

# Define required modules
$requiredModules = @(
    @{
        Name = "Pester"
        MinVersion = "5.0.0"
        Description = "PowerShell testing framework"
        Essential = $true
    },
    @{
        Name = "PSScriptAnalyzer"
        MinVersion = "1.20.0"
        Description = "PowerShell code quality analyzer"
        Essential = $true
    },
    @{
        Name = "powershell-yaml"
        MinVersion = "0.4.0"
        Description = "YAML configuration support"
        Essential = $false
    },
    @{
        Name = "InvokeBuild"
        MinVersion = "5.8.0"
        Description = "Build automation framework"
        Essential = $false
    }
)

$installResults = @()

foreach ($module in $requiredModules) {
    Write-Host "`nProcessing: $($module.Name)" -ForegroundColor White
    
    try {
        # Check if module is already installed
        $installedModule = Get-Module -ListAvailable -Name $module.Name | 
                          Sort-Object Version -Descending | 
                          Select-Object -First 1
        
        $shouldInstall = $Force -or 
                        ($null -eq $installedModule) -or 
                        ($installedModule.Version -lt [Version]$module.MinVersion)
        
        if ($shouldInstall) {
            Write-Host "   Installing $($module.Name)..." -ForegroundColor Yellow
            
            $installParams = @{
                Name = $module.Name
                Force = $true
                SkipPublisherCheck = $true
                AllowClobber = $true
            }
            
            # Try user scope first, then AllUsers if admin
            try {
                Install-Module @installParams -Scope CurrentUser -ErrorAction Stop
                $scope = "CurrentUser"
            }
            catch {
                if ($isAdmin) {
                    Install-Module @installParams -Scope AllUsers -ErrorAction Stop
                    $scope = "AllUsers"
                }
                else {
                    throw $_
                }
            }
            
            # Verify installation
            $installedModule = Get-Module -ListAvailable -Name $module.Name | 
                              Sort-Object Version -Descending | 
                              Select-Object -First 1
            
            if ($installedModule) {
                Write-ToolStatus $module.Name $true $installedModule.Version "Installed to $scope"
                $installResults += @{
                    Module = $module.Name
                    Success = $true
                    Version = $installedModule.Version
                    Essential = $module.Essential
                }
            }
            else {
                throw "Installation verification failed"
            }
        }
        else {
            Write-ToolStatus $module.Name $true $installedModule.Version "Already installed (current)"
            $installResults += @{
                Module = $module.Name
                Success = $true
                Version = $installedModule.Version
                Essential = $module.Essential
            }
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-ToolStatus $module.Name $false "" "Error: $errorMsg"
        $installResults += @{
            Module = $module.Name
            Success = $false
            Error = $errorMsg
            Essential = $module.Essential
        }
    }
}

# Summary
Write-Host "`nInstallation Summary" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

$successfulEssential = ($installResults | Where-Object { $_.Success -and $_.Essential }).Count
$totalEssential = ($requiredModules | Where-Object { $_.Essential }).Count
$successfulOptional = ($installResults | Where-Object { $_.Success -and -not $_.Essential }).Count
$totalOptional = ($requiredModules | Where-Object { -not $_.Essential }).Count

Write-Host "Essential Tools: $successfulEssential/$totalEssential installed" -ForegroundColor $(if ($successfulEssential -eq $totalEssential) { "Green" } else { "Yellow" })
Write-Host "Optional Tools:  $successfulOptional/$totalOptional installed" -ForegroundColor Green

# Check if ready for testing
$readyForTesting = $successfulEssential -eq $totalEssential

if ($readyForTesting) {
    Write-Host "`n[SUCCESS] Testing environment is ready!" -ForegroundColor Green
    Write-Host "You can now run: .\scripts\Test-Prerequisites.ps1" -ForegroundColor White
    exit 0
}
else {
    Write-Host "`n[WARNING] Some essential tools failed to install." -ForegroundColor Yellow
    Write-Host "Testing capabilities may be limited." -ForegroundColor Yellow
    
    # Show failed essential modules
    $failedEssential = $installResults | Where-Object { -not $_.Success -and $_.Essential }
    if ($failedEssential) {
        Write-Host "`nFailed essential modules:" -ForegroundColor Red
        foreach ($failed in $failedEssential) {
            Write-Host "  - $($failed.Module): $($failed.Error)" -ForegroundColor Red
        }
    }
    exit 1
}

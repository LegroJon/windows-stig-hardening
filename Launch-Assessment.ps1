<#
.SYNOPSIS
    Windows 11 STIG Assessment Tool - Main Launcher

.DESCRIPTION
    Simple launcher script that provides quick access to the STIG assessment tools.
    This script redirects to the appropriate tools in the scripts/ folder.
    Automatically handles PowerShell execution policy issues.

.NOTES
    Author: Jonathan Legro
    Version: 1.0.0

.EXAMPLE
    .\Launch-Assessment.ps1
    Launch the quick assessment menu
#>

# Function to check and handle execution policy
function Test-ExecutionPolicy {
    $currentPolicy = Get-ExecutionPolicy -Scope Process
    $effectivePolicy = Get-ExecutionPolicy

    Write-Host "[STIG] Checking PowerShell execution policy..." -ForegroundColor Gray

    if ($effectivePolicy -eq "Restricted" -or $effectivePolicy -eq "AllSigned") {
        Write-Host "[WARNING] PowerShell execution policy is restrictive: $effectivePolicy" -ForegroundColor Yellow
        Write-Host "[INFO] This tool requires script execution to perform STIG assessments." -ForegroundColor Gray

    $response = Read-Host "[INFO] Temporarily allow script execution for this session? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y' -or $response -eq 'yes') {
            try {
                Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
                Write-Host "[SUCCESS] Execution policy temporarily set to Bypass for this session" -ForegroundColor Green
                Write-Host "[INFO] This change only affects the current PowerShell session" -ForegroundColor Gray
                return $true
            }
            catch {
                Write-Host "[ERROR] Failed to modify execution policy: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "[MANUAL] Please run: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Yellow
                return $false
            }
        }
        else {
            Write-Host "[INFO] Assessment cancelled. To run manually:" -ForegroundColor Gray
            Write-Host "[INFO] Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor White
            Write-Host "[INFO] .\Launch-Assessment.ps1" -ForegroundColor White
            return $false
        }
    }
    else {
        Write-Host "[SUCCESS] Execution policy allows script execution: $effectivePolicy" -ForegroundColor Green
        return $true
    }
}

# Check execution policy first
if (-not (Test-ExecutionPolicy)) {
    Write-Host "`n[ERROR] Execution policy check failed. Assessment tool cannot continue." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "`n[STIG] Windows 11 STIG Assessment Tool" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Check admin privileges with VS Code awareness
$adminResult = & ".\scripts\Test-AdminInVSCode.ps1"
if ($adminResult -eq $null) {
    # User chose to exit to get admin privileges
    exit 0
}

Write-Host "`n[INFO] Choose your launcher:" -ForegroundColor White
Write-Host "[INFO] 1. Quick Assessment Menu (Recommended)" -ForegroundColor Green
Write-Host "[INFO] 2. Advanced CLI Tool" -ForegroundColor Yellow
Write-Host "[INFO] 3. Exit" -ForegroundColor Gray

$choice = Read-Host "`nEnter your choice (1-3)"

switch ($choice) {
    "1" {
    Write-Host "`n[RUNNING] Launching Quick Assessment Menu..." -ForegroundColor Green
        & ".\scripts\Quick-Assessment.ps1"
    }
    "2" {
    Write-Host "`n[RUNNING] Launching Advanced CLI Tool..." -ForegroundColor Yellow
    Write-Host "[INFO] Usage: .\scripts\Start-STIGAssessment.ps1 [parameters]" -ForegroundColor Gray
    Write-Host "[INFO] Run: Get-Help .\scripts\Start-STIGAssessment.ps1 -Detailed" -ForegroundColor Gray
        Write-Host ""
        & ".\scripts\Start-STIGAssessment.ps1" -RequestAdmin
    }
    "3" {
    Write-Host "[INFO] Goodbye!" -ForegroundColor Gray
        exit 0
    }
    default {
    Write-Host "[WARNING] Invalid choice. Please run the script again." -ForegroundColor Red
        exit 1
    }
}

<#
.SYNOPSIS
    Windows 11 STIG Assessment Tool - Main Launcher

.DESCRIPTION
    Simple launcher script that provides quick access to the STIG assessment tools.
    This script redirects to the appropriate tools in the scripts/ folder.

.NOTES
    Author: Jonathan Legro
    Version: 1.0.0
    
.EXAMPLE
    .\Launch-Assessment.ps1
    Launch the quick assessment menu
#>

Write-Host "`n[STIG] Windows 11 STIG Assessment Tool" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Check admin privileges with VS Code awareness
$adminResult = & ".\scripts\Test-AdminInVSCode.ps1"
if ($adminResult -eq $null) {
    # User chose to exit to get admin privileges
    exit 0
}

Write-Host "`nChoose your launcher:" -ForegroundColor White
Write-Host "1. Quick Assessment Menu (Recommended)" -ForegroundColor Green
Write-Host "2. Advanced CLI Tool" -ForegroundColor Yellow
Write-Host "3. Exit" -ForegroundColor Gray

$choice = Read-Host "`nEnter your choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host "`nLaunching Quick Assessment Menu..." -ForegroundColor Green
        & ".\scripts\Quick-Assessment.ps1"
    }
    "2" {
        Write-Host "`nLaunching Advanced CLI Tool..." -ForegroundColor Yellow
        Write-Host "Usage: .\scripts\Start-STIGAssessment.ps1 [parameters]" -ForegroundColor Gray
        Write-Host "Run: Get-Help .\scripts\Start-STIGAssessment.ps1 -Detailed" -ForegroundColor Gray
        Write-Host ""
        & ".\scripts\Start-STIGAssessment.ps1" -RequestAdmin
    }
    "3" {
        Write-Host "Goodbye!" -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
        exit 1
    }
}

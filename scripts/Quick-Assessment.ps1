<#
.SYNOPSIS
    Quick STIG Assessment Launcher with Report Options

.DESCRIPTION
    Provides easy options to run STIG assessments with different report formats.
    This is a user-friendly wrapper around Start-STIGAssessment.ps1
#>

Write-Host "[STIG] Windows 11 STIG Assessment Tool - Quick Launcher" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Check if we have admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[WARNING] Not running with Administrator privileges" -ForegroundColor Yellow
    Write-Host "          Some checks may not work accurately without admin rights." -ForegroundColor Gray
    Write-Host ""
}

Write-Host "[INFO] Choose your assessment options:" -ForegroundColor White
Write-Host ""
Write-Host "[INFO] 1. HTML - Generate HTML Report Only" -ForegroundColor Green
Write-Host "   Professional web-based report for viewing and sharing"
Write-Host ""
Write-Host "[INFO] 2. CSV - Generate CSV Report Only" -ForegroundColor Green
Write-Host "   Spreadsheet format for data analysis"
Write-Host ""
Write-Host "[INFO] 3. JSON - Generate JSON Report Only" -ForegroundColor Green
Write-Host "   Technical format for automation and integration"
Write-Host ""
Write-Host "[INFO] 4. ALL - Generate ALL Report Formats" -ForegroundColor Cyan
Write-Host "   HTML, CSV, and JSON reports"
Write-Host ""
Write-Host "[INFO] 5. QUICK - Quick Assessment (JSON only)" -ForegroundColor Yellow
Write-Host "   Fast scan with basic JSON output"
Write-Host ""
Write-Host "[INFO] 6. CRITICAL - Filter Critical Rules Only (CAT I)" -ForegroundColor Red
Write-Host "   Test only the most critical security requirements"
Write-Host ""
Write-Host "[INFO] 0. EXIT" -ForegroundColor Gray
Write-Host ""

do {
    $choice = Read-Host "Enter your choice (0-6)"

    switch ($choice) {
        "1" {
            Write-Host "[RUNNING] HTML assessment with HTML report..." -ForegroundColor Green
            .\scripts\Start-STIGAssessment.ps1 -Format HTML -RequestAdmin
            break
        }
        "2" {
            Write-Host "[RUNNING] CSV assessment with CSV report..." -ForegroundColor Green
            .\scripts\Start-STIGAssessment.ps1 -Format CSV -RequestAdmin
            break
        }
        "3" {
            Write-Host "[RUNNING] JSON assessment with JSON report..." -ForegroundColor Green
            .\scripts\Start-STIGAssessment.ps1 -Format JSON -RequestAdmin
            break
        }
        "4" {
            Write-Host "[RUNNING] Assessment with ALL report formats..." -ForegroundColor Cyan
            .\scripts\Start-STIGAssessment.ps1 -Format ALL -RequestAdmin
            break
        }
        "5" {
            Write-Host "[RUNNING] Quick assessment..." -ForegroundColor Yellow
            .\scripts\Start-STIGAssessment.ps1
            break
        }
        "6" {
            Write-Host "[RUNNING] Critical rules assessment..." -ForegroundColor Red
            .\scripts\Start-STIGAssessment.ps1 -RuleFilter "CAT I" -Format HTML -RequestAdmin
            break
        }
        "0" {
            Write-Host "[INFO] Goodbye!" -ForegroundColor Gray
            exit 0
        }
        default {
            Write-Host "[ERROR] Invalid choice. Please enter 0-6." -ForegroundColor Red
        }
    }
} while ($choice -notin @("0","1","2","3","4","5","6"))

# After assessment completes
Write-Host ""
Write-Host "[REPORT] Check the 'reports' folder for your generated files!" -ForegroundColor Green
Write-Host ""

# Ask if they want to open the reports folder
$openFolder = Read-Host "Would you like to open the reports folder? (y/n)"
if ($openFolder -eq "y" -or $openFolder -eq "Y" -or $openFolder -eq "yes") {
    if (Test-Path ".\reports") {
        Start-Process -FilePath "explorer.exe" -ArgumentList ".\reports"
    } else {
        Write-Host "Reports folder not found." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[COMPLETE] Assessment complete!" -ForegroundColor Green

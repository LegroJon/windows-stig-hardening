# Simple Admin Test - Run this manually in an Admin PowerShell window

Write-Host "🛡️ STIG Assessment - Admin Test" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Test if we have admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
    Write-Host ""
    
    # Test one rule first
    Write-Host "Testing individual rule..." -ForegroundColor Yellow
    . ".\rules\core\WN11-SO-000025.ps1"
    $result = Test-WN11SO000025
    
    Write-Host "Rule ID: $($result.RuleID)" -ForegroundColor White
    Write-Host "Status: $($result.Status)" -ForegroundColor $(if ($result.Status -eq "Compliant") { "Green" } elseif ($result.Status -eq "Non-Compliant") { "Red" } else { "Yellow" })
    Write-Host "Evidence: $($result.Evidence)" -ForegroundColor Gray
    Write-Host ""
    
    # If that worked, run full assessment
    if ($result.Status -ne "Error") {
        Write-Host "✅ Individual rule test passed! Running full assessment..." -ForegroundColor Green
        .\scripts\Start-STIGAssessment.ps1
    } else {
        Write-Host "❌ Individual rule test failed. Check error above." -ForegroundColor Red
    }
} else {
    Write-Host "❌ Not running with Administrator privileges" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Right-click Start Menu" -ForegroundColor White
    Write-Host "2. Select 'Windows PowerShell (Admin)'" -ForegroundColor White
    Write-Host "3. Accept the UAC prompt" -ForegroundColor White
    Write-Host "4. Navigate to this folder:" -ForegroundColor White
    Write-Host "   cd `"$PWD`"" -ForegroundColor Cyan
    Write-Host "5. Run this script:" -ForegroundColor White
    Write-Host "   .\Test-Admin.ps1" -ForegroundColor Cyan
}

Read-Host "`nPress Enter to continue"

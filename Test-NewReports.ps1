# Test New STIG Reporting Options
# Quick validation script for unified reporting

Write-Host "[STIG] Testing New Report Formats..." -ForegroundColor Cyan

# Test SUMMARY format
Write-Host "`n[TEST] Generating SUMMARY report..." -ForegroundColor Yellow
try {
    .\scripts\Start-STIGAssessment.ps1 -Format SUMMARY -Verbose
    Write-Host "[SUCCESS] SUMMARY format works!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] SUMMARY format failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test EXECUTIVE format
Write-Host "`n[TEST] Generating EXECUTIVE report..." -ForegroundColor Yellow
try {
    .\scripts\Start-STIGAssessment.ps1 -Format EXECUTIVE -Verbose
    Write-Host "[SUCCESS] EXECUTIVE format works!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] EXECUTIVE format failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[INFO] New report options available:" -ForegroundColor Cyan
Write-Host "  - SUMMARY: Single-page overview (no clutter)" -ForegroundColor White
Write-Host "  - EXECUTIVE: Business-level report" -ForegroundColor White
Write-Host "  - Original options: JSON, HTML, CSV, ALL" -ForegroundColor Gray

Write-Host "`n[NEXT] Try: .\scripts\Start-STIGAssessment.ps1 -Format SUMMARY" -ForegroundColor Green

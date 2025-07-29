function Test-Syntax {
    Write-Host "Testing syntax..."
}

function Show-AssessmentResults {
    param([hashtable]$Results)
    
    Write-Host "`n🎯 Assessment Results" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Cyan
    Write-Host "Total Rules:    " -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.TotalRules -ForegroundColor Green
    Write-Host "✅ Compliant:    " -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.Compliant -ForegroundColor Green
    Write-Host "❌ Non-Compliant:" -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.NonCompliant -ForegroundColor Red
    Write-Host "⚠️  Errors:       " -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.Errors -ForegroundColor Yellow
    Write-Host "📊 Compliance:   " -NoNewline -ForegroundColor White
    Write-Host "$($Results.Statistics.CompliancePercentage)%" -ForegroundColor $(
        if ($Results.Statistics.CompliancePercentage -ge 90) { "Green" }
        elseif ($Results.Statistics.CompliancePercentage -ge 75) { "Yellow" }
        else { "Red" }
    )
    Write-Host "=" * 30 -ForegroundColor Cyan
}

Test-Syntax
Write-Host "Syntax test completed"

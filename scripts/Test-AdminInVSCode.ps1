<#
.SYNOPSIS
    Admin privilege handler optimized for VS Code terminal usage

.DESCRIPTION
    This script detects if running in VS Code terminal and provides appropriate
    guidance for admin elevation without breaking the VS Code workflow.
#>

function Test-IsElevated {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsVSCodeTerminal {
    # Check if running in VS Code integrated terminal
    return ($env:TERM_PROGRAM -eq "vscode") -or ($env:VSCODE_PID -ne $null)
}

function Show-AdminGuidance {
    Write-Host "`n[ADMIN] Administrator privileges required for accurate STIG assessment" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    
    if (Test-IsVSCodeTerminal) {
        Write-Host "`n[INFO] VS Code Terminal Detected" -ForegroundColor Cyan
        Write-Host "The standard UAC elevation opens a new window, breaking VS Code workflow." -ForegroundColor Gray
        Write-Host "`n[RECOMMENDED] VS Code Admin Solutions:" -ForegroundColor Green
        Write-Host "1. [BEST] Restart VS Code as Administrator:" -ForegroundColor White
        Write-Host "   - Close VS Code" -ForegroundColor Gray
        Write-Host "   - Right-click VS Code icon -> 'Run as administrator'" -ForegroundColor Gray
        Write-Host "   - Reopen your project" -ForegroundColor Gray
        Write-Host "   - Run scripts normally in integrated terminal" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. [ALTERNATIVE] Use External PowerShell:" -ForegroundColor White
        Write-Host "   - Open PowerShell as Administrator (outside VS Code)" -ForegroundColor Gray
        Write-Host "   - Navigate to: $PWD" -ForegroundColor Gray
        Write-Host "   - Run: .\Launch-Assessment.ps1" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. [QUICK TEST] Run without admin (limited functionality):" -ForegroundColor White
        Write-Host "   - Some checks may show inaccurate results" -ForegroundColor Gray
        Write-Host "   - Good for testing script functionality" -ForegroundColor Gray
    } else {
        Write-Host "`n[STANDARD] PowerShell Terminal Detected" -ForegroundColor Cyan
        Write-Host "1. Close this PowerShell window" -ForegroundColor White
        Write-Host "2. Right-click Start -> 'Windows PowerShell (Admin)'" -ForegroundColor White
        Write-Host "3. Navigate to: $PWD" -ForegroundColor White
        Write-Host "4. Run: .\Launch-Assessment.ps1" -ForegroundColor White
    }
    
    Write-Host "`n[WARNING] Without admin privileges:" -ForegroundColor Red
    Write-Host "- Registry checks may fail" -ForegroundColor Gray
    Write-Host "- Security policy reads may be incomplete" -ForegroundColor Gray
    Write-Host "- Some STIG rules cannot be accurately assessed" -ForegroundColor Gray
}

# Main execution
Write-Host "[STIG] Admin Privilege Check" -ForegroundColor Cyan

if (Test-IsElevated) {
    Write-Host "[SUCCESS] Running with Administrator privileges" -ForegroundColor Green
    Write-Host "All STIG assessments will work correctly." -ForegroundColor Gray
    return $true
} else {
    Show-AdminGuidance
    Write-Host ""
    $continue = Read-Host "Continue without admin privileges? (y/N)"
    if ($continue -eq 'y' -or $continue -eq 'Y') {
        Write-Host "[WARNING] Continuing with limited functionality..." -ForegroundColor Yellow
        return $false
    } else {
        Write-Host "[INFO] Please follow the guidance above to run with admin privileges." -ForegroundColor Cyan
        return $null
    }
}

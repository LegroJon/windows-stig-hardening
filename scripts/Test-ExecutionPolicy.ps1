<#
.SYNOPSIS
    PowerShell Execution Policy Helper for STIG Assessment Tool

.DESCRIPTION
    Handles PowerShell execution policy checks and provides user-friendly
    guidance for resolving policy restrictions. Designed for enterprise
    environments where execution policies may be strictly controlled.

.PARAMETER AutoFix
    Automatically apply temporary execution policy bypass without user prompt

.PARAMETER Silent
    Suppress output messages and return boolean result only

.NOTES
    Author: Jonathan Legro
    Version: 1.0.0
    
.EXAMPLE
    .\Test-ExecutionPolicy.ps1
    Check execution policy with user interaction

.EXAMPLE
    .\Test-ExecutionPolicy.ps1 -AutoFix
    Automatically apply temporary bypass if needed

.EXAMPLE
    $canRun = .\Test-ExecutionPolicy.ps1 -Silent
    Check policy silently and return boolean result
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$AutoFix,
    
    [Parameter(Mandatory = $false)]
    [switch]$Silent
)

function Test-ExecutionPolicyCompliance {
    param(
        [bool]$AutoFix = $false,
        [bool]$Silent = $false
    )
    
    $currentPolicy = Get-ExecutionPolicy -Scope Process
    $effectivePolicy = Get-ExecutionPolicy
    
    if (-not $Silent) {
        Write-Host "[STIG] Checking PowerShell execution policy..." -ForegroundColor Gray
        Write-Host "[INFO] Current policy: $effectivePolicy (Process: $currentPolicy)" -ForegroundColor Gray
    }
    
    # Check if policy allows script execution
    $restrictivePolicies = @("Restricted", "AllSigned")
    $needsFix = $effectivePolicy -in $restrictivePolicies
    
    if (-not $needsFix) {
        if (-not $Silent) {
            Write-Host "[SUCCESS] Execution policy allows script execution: $effectivePolicy" -ForegroundColor Green
        }
        return $true
    }
    
    # Policy is restrictive - needs fixing
    if (-not $Silent) {
        Write-Host "[WARNING] PowerShell execution policy is restrictive: $effectivePolicy" -ForegroundColor Yellow
        Write-Host "[INFO] STIG assessment tools require script execution capability" -ForegroundColor Gray
    }
    
    if ($AutoFix) {
        try {
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
            if (-not $Silent) {
                Write-Host "[SUCCESS] Execution policy temporarily set to Bypass for this session" -ForegroundColor Green
                Write-Host "[SECURITY] This change only affects the current PowerShell session" -ForegroundColor Cyan
            }
            return $true
        }
        catch {
            if (-not $Silent) {
                Write-Host "[ERROR] Failed to modify execution policy: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "[MANUAL] Administrator rights may be required" -ForegroundColor Yellow
            }
            return $false
        }
    }
    
    # Interactive mode - ask user
    if (-not $Silent) {
        Write-Host "`n[SECURITY] The tool needs to temporarily modify execution policy for this session." -ForegroundColor Cyan
        Write-Host "[DETAILS] This will:" -ForegroundColor Gray
        Write-Host "          • Allow PowerShell scripts to run in THIS session only" -ForegroundColor Gray
        Write-Host "          • NOT affect system-wide security settings" -ForegroundColor Gray
        Write-Host "          • Revert automatically when PowerShell closes" -ForegroundColor Gray
        
        $response = Read-Host "`n[PROMPT] Allow temporary script execution for STIG assessment? (y/N)"
        
        if ($response -eq 'y' -or $response -eq 'Y' -or $response -eq 'yes' -or $response -eq 'YES') {
            try {
                Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
                Write-Host "[SUCCESS] Execution policy temporarily set to Bypass for this session" -ForegroundColor Green
                Write-Host "[SECURITY] System-wide policies remain unchanged" -ForegroundColor Cyan
                return $true
            }
            catch {
                Write-Host "[ERROR] Failed to modify execution policy: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "[TROUBLESHOOTING] Try these solutions:" -ForegroundColor Yellow
                Write-Host "                  1. Run PowerShell as Administrator" -ForegroundColor White
                Write-Host "                  2. Run: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor White
                Write-Host "                  3. Contact your system administrator" -ForegroundColor White
                return $false
            }
        }
        else {
            Write-Host "[INFO] Assessment cancelled by user" -ForegroundColor Gray
            Write-Host "[MANUAL] To run STIG assessment manually:" -ForegroundColor Yellow
            Write-Host "         Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor White
            Write-Host "         .\Launch-Assessment.ps1" -ForegroundColor White
            return $false
        }
    }
    
    return $false
}

# Main execution
$result = Test-ExecutionPolicyCompliance -AutoFix:$AutoFix -Silent:$Silent

if ($Silent) {
    return $result
}
else {
    exit $(if ($result) { 0 } else { 1 })
}

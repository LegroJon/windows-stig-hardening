<#
.SYNOPSIS
    STIG Rule Generator - Converts DISA STIG documentation into PowerShell rule scripts

.DESCRIPTION
    This script helps generate PowerShell rule scripts from DISA STIG documentation.
    It provides templates and guidance for creating standardized STIG compliance checks.

.PARAMETER RuleID
    STIG Rule ID (e.g., WN11-SO-000015)

.PARAMETER RuleTitle
    Human-readable title for the rule

.PARAMETER Category
    STIG category (CAT I, CAT II, CAT III)

.PARAMETER CheckProcedure
    The check procedure from STIG documentation

.PARAMETER FixProcedure
    The fix procedure from STIG documentation

.EXAMPLE
    .\New-STIGRule.ps1 -RuleID "WN11-SO-000015" -RuleTitle "PowerShell Script Block Logging" -Category "CAT II"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RuleID,
    
    [Parameter(Mandatory = $true)]
    [string]$RuleTitle,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("CAT I", "CAT II", "CAT III")]
    [string]$Category,
    
    [Parameter(Mandatory = $false)]
    [string]$CheckProcedure = "",
    
    [Parameter(Mandatory = $false)]
    [string]$FixProcedure = ""
)

# Generate function name from rule ID
$functionName = "Test-" + ($RuleID -replace '[^a-zA-Z0-9]', '')

# Create rule script template
$ruleTemplate = @"
<#
.SYNOPSIS
    $RuleTitle

.DESCRIPTION
    STIG Rule: $RuleID
    Category: $Category
    
    $RuleTitle

.NOTES
    Generated from DISA STIG documentation
    Rule ID: $RuleID
    Severity: $Category
#>

function $functionName {
    try {
        # TODO: Implement check procedure based on STIG documentation
        # Check Procedure from STIG:
        # $CheckProcedure
        
        # Example implementation - REPLACE WITH ACTUAL CHECK
        `$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
        `$registryValue = "EnableScriptBlockLogging"
        
        if (Test-Path `$registryPath) {
            `$currentValue = Get-ItemProperty -Path `$registryPath -Name `$registryValue -ErrorAction SilentlyContinue
            
            if (`$currentValue.`$registryValue -eq 1) {
                `$status = "Compliant"
                `$evidence = "ScriptBlockLogging is enabled (Value: `$(`$currentValue.`$registryValue))"
            } else {
                `$status = "Non-Compliant"
                `$evidence = "ScriptBlockLogging is disabled or not configured properly"
            }
        } else {
            `$status = "Non-Compliant"
            `$evidence = "Registry path does not exist: `$registryPath"
        }
        
        return @{
            RuleID   = "$RuleID"
            Status   = `$status
            Evidence = `$evidence
            FixText  = "$FixProcedure"
        }
    }
    catch {
        return @{
            RuleID   = "$RuleID"
            Status   = "Error"
            Evidence = "Error checking compliance: `$(`$_.Exception.Message)"
            FixText  = "$FixProcedure"
        }
    }
}
"@

# Create the rule file
$ruleFileName = "$RuleID.ps1"
$ruleFilePath = Join-Path ".\rules\core" $ruleFileName

# Write the rule script
$ruleTemplate | Out-File -FilePath $ruleFilePath -Encoding UTF8

Write-Host "[SUCCESS] STIG Rule script created: $ruleFilePath" -ForegroundColor Green
Write-Host "[NEXT] Next steps:" -ForegroundColor Yellow
Write-Host "   1. Edit the script to implement the actual check procedure" -ForegroundColor Gray
Write-Host "   2. Replace the example registry check with STIG-specific logic" -ForegroundColor Gray
Write-Host "   3. Test the rule: .\scripts\Start-STIGAssessment.ps1 -RuleFilter '$RuleID'" -ForegroundColor Gray
Write-Host "   4. Update the FixText with actual remediation steps" -ForegroundColor Gray

# Display template for reference
Write-Host "`n[SUMMARY] Rule Template Summary:" -ForegroundColor Cyan
Write-Host "Rule ID: $RuleID" -ForegroundColor White
Write-Host "Function: $functionName" -ForegroundColor White
Write-Host "File: $ruleFilePath" -ForegroundColor White

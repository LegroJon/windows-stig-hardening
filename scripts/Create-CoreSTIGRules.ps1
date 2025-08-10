<#
.SYNOPSIS
    Manual STIG Rule Extractor - Creates key STIG rules based on common Windows 11 requirements

.DESCRIPTION
    This script creates essential STIG compliance rules based on the most common
    Windows 11 security requirements found in DISA STIG documentation.

.EXAMPLE
    .\Create-CoreSTIGRules.ps1
#>

Write-Host "`n[STIG] Creating Core Windows 11 STIG Rules" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Define core STIG rules based on common Windows 11 requirements
$coreRules = @(
    @{
        RuleID = "WN11-SO-000005"
        Title = "PowerShell 2.0 must be disabled"
        Category = "CAT I"
        CheckProcedure = "Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root"
        FixProcedure = "Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root"
    },
    @{
        RuleID = "WN11-SO-000010"
        Title = "Simple TCP/IP Services must be disabled"
        Category = "CAT II"
        CheckProcedure = "Get-WindowsOptionalFeature -Online -FeatureName SimpleTCPIP"
        FixProcedure = "Disable-WindowsOptionalFeature -Online -FeatureName SimpleTCPIP"
    },
    @{
        RuleID = "WN11-SO-000015"
        Title = "Telnet Client must be disabled"
        Category = "CAT II"
        CheckProcedure = "Get-WindowsOptionalFeature -Online -FeatureName TelnetClient"
        FixProcedure = "Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient"
    },
    @{
        RuleID = "WN11-SO-000020"
        Title = "TFTP Client must be disabled"
        Category = "CAT II"
        CheckProcedure = "Get-WindowsOptionalFeature -Online -FeatureName TFTP"
        FixProcedure = "Disable-WindowsOptionalFeature -Online -FeatureName TFTP"
    },
    @{
        RuleID = "WN11-AU-000010"
        Title = "Audit Account Lockout must be configured"
        Category = "CAT II"
        CheckProcedure = "auditpol /get /subcategory:'Account Lockout'"
        FixProcedure = "auditpol /set /subcategory:'Account Lockout' /success:enable /failure:enable"
    },
    @{
        RuleID = "WN11-AU-000015"
        Title = "Audit Logon must be configured"
        Category = "CAT II"
        CheckProcedure = "auditpol /get /subcategory:'Logon'"
        FixProcedure = "auditpol /set /subcategory:'Logon' /success:enable /failure:enable"
    },
    @{
        RuleID = "WN11-AU-000020"
        Title = "Audit Process Creation must be configured"
        Category = "CAT II"
        CheckProcedure = "auditpol /get /subcategory:'Process Creation'"
        FixProcedure = "auditpol /set /subcategory:'Process Creation' /success:enable"
    },
    @{
        RuleID = "WN11-CC-000030"
        Title = "DEP must be configured to OptOut"
        Category = "CAT I"
        CheckProcedure = "bcdedit /enum {current} | findstr nx"
        FixProcedure = "bcdedit /set {current} nx OptOut"
    }
)

$createdCount = 0

foreach ($rule in $coreRules) {
    try {
        # Generate rule script using our existing tool
        $result = & ".\scripts\New-STIGRule.ps1" -RuleID $rule.RuleID -RuleTitle $rule.Title -Category $rule.Category -CheckProcedure $rule.CheckProcedure -FixProcedure $rule.FixProcedure

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Created: $($rule.RuleID)" -ForegroundColor Green
            $createdCount++
        }
    }
    catch {
        Write-Warning "Failed to create rule $($rule.RuleID): $($_.Exception.Message)"
    }
}

Write-Host "`n[SUMMARY] Summary" -ForegroundColor Cyan
Write-Host "[SUMMARY] Created $createdCount out of $($coreRules.Count) core STIG rules" -ForegroundColor Green

Write-Host "`n[NEXT] Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the rules: .\scripts\Start-STIGAssessment.ps1" -ForegroundColor Gray
Write-Host "2. Review and customize rule implementations" -ForegroundColor Gray
Write-Host "3. Add more rules from your SCAP file manually" -ForegroundColor Gray

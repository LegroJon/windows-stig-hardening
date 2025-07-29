<#
.SYNOPSIS
    Data Execution Prevention (DEP) Configuration

.DESCRIPTION
    STIG Rule: WN11-SO-000015
    Category: CAT I
    
    Data Execution Prevention (DEP) Configuration

.NOTES
    Generated from DISA STIG documentation
    Rule ID: WN11-SO-000015
    Severity: CAT I
#>

function Test-WN11SO000015 {
    try {
        # Check Data Execution Prevention (DEP) configuration
        # DEP should be enabled for essential Windows programs and services only (OptIn) or for all programs (AlwaysOn)
        
        $depStatus = Get-WmiObject -Class "Win32_OperatingSystem" | Select-Object DataExecutionPrevention_SupportPolicy
        
        # DEP Policy values:
        # 0 = OptOut - DEP enabled for all except excluded
        # 1 = OptIn - DEP enabled for essential Windows programs only 
        # 2 = AlwaysOff - DEP disabled
        # 3 = AlwaysOn - DEP enabled for all programs
        
        $policy = $depStatus.DataExecutionPrevention_SupportPolicy
        
        if ($policy -eq 1 -or $policy -eq 3) {
            $status = "Compliant"
            $policyName = switch ($policy) {
                1 { "OptIn (Essential Windows programs only)" }
                3 { "AlwaysOn (All programs)" }
            }
            $evidence = "DEP is properly configured: $policyName (Policy: $policy)"
        } else {
            $status = "Non-Compliant"
            $policyName = switch ($policy) {
                0 { "OptOut (All except excluded)" }
                2 { "AlwaysOff (Disabled)" }
                default { "Unknown ($policy)" }
            }
            $evidence = "DEP is not properly configured: $policyName (Policy: $policy)"
        }
        
        return @{
            RuleID   = "WN11-SO-000015"
            Status   = $status
            Evidence = $evidence
            FixText  = "Configure DEP via System Properties > Advanced > Performance Settings > Data Execution Prevention. Select 'Turn on DEP for essential Windows programs and services only' or 'Turn on DEP for all programs and services except those I select'"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000015"
            Status   = "Error"
            Evidence = "Error checking DEP configuration: $($_.Exception.Message)"
            FixText  = ""
        }
    }
}

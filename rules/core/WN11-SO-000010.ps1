<#
.SYNOPSIS
    Simple TCP/IP Services must be disabled

.DESCRIPTION
    STIG Rule: WN11-SO-000010
    Category: CAT II
    
    The Simple TCP/IP Services feature must be disabled as it provides unnecessary 
    network services that could be exploited by attackers.

.NOTES
    Generated from DISA STIG documentation
    Rule ID: WN11-SO-000010
    Severity: CAT II
    Check: Verify Simple TCP/IP Services is disabled
    Fix: Disable Simple TCP/IP Services feature
#>

function Test-WN11SO000010 {
    <#
    .SYNOPSIS
        Tests if Simple TCP/IP Services is disabled on Windows 11
    
    .DESCRIPTION
        Checks if the Simple TCP/IP Services feature is disabled to comply with DISA STIG requirements.
        This feature provides unnecessary network services that could present security risks.
    
    .OUTPUTS
        Returns a hashtable with RuleID, Status, Evidence, and FixText
    #>
    
    try {
        # Check if Simple TCP/IP Services feature is installed/enabled
        $feature = Get-WindowsOptionalFeature -Online -FeatureName "SimpleTCP" -ErrorAction Stop
        
        if ($feature.State -eq "Disabled") {
            $status = "Compliant"
            $evidence = "Simple TCP/IP Services is disabled (State: $($feature.State))"
            $fixText = "No action required - Simple TCP/IP Services is properly disabled"
        } elseif ($feature.State -eq "Enabled") {
            $status = "Non-Compliant"
            $evidence = "Simple TCP/IP Services is enabled (State: $($feature.State))"
            $fixText = "Run: Disable-WindowsOptionalFeature -Online -FeatureName SimpleTCP -NoRestart"
        } else {
            $status = "Non-Compliant"
            $evidence = "Simple TCP/IP Services state is unknown (State: $($feature.State))"
            $fixText = "Verify feature status and disable if necessary: Disable-WindowsOptionalFeature -Online -FeatureName SimpleTCP -NoRestart"
        }
        
        return @{
            RuleID   = "WN11-SO-000010"
            Status   = $status
            Evidence = $evidence
            FixText  = $fixText
        }
    }
    catch {
        # If feature doesn't exist, it's effectively "disabled"
        if ($_.Exception.Message -like "*feature name SimpleTCP was not found*" -or 
            $_.Exception.Message -like "*Cannot find a feature*") {
            return @{
                RuleID   = "WN11-SO-000010"
                Status   = "Compliant"
                Evidence = "Simple TCP/IP Services feature is not available (not installed)"
                FixText  = "No action required - feature is not present on this system"
            }
        }
        
        return @{
            RuleID   = "WN11-SO-000010"
            Status   = "Error"
            Evidence = "Error checking Simple TCP/IP Services: $($_.Exception.Message)"
            FixText  = "Manually verify Simple TCP/IP Services status: Get-WindowsOptionalFeature -Online -FeatureName SimpleTCP"
        }
    }
}

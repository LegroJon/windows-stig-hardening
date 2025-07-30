<#
.SYNOPSIS
    Telnet Client Feature Disabled

.DESCRIPTION
    STIG Rule: WN11-SO-000025
    Category: CAT II
    
    Telnet Client Feature Disabled

.NOTES
    Generated from DISA STIG documentation
    Rule ID: WN11-SO-000025
    Severity: CAT II
#>

function Test-WN11SO000025 {
    try {
        # Check if Telnet Client feature is disabled
        # Telnet transmits data in clear text and should be disabled
        
        $telnetFeature = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient -ErrorAction SilentlyContinue
        
        if ($telnetFeature) {
            if ($telnetFeature.State -eq "Disabled") {
                $status = "Compliant"
                $evidence = "Telnet Client is disabled (State: $($telnetFeature.State))"
            } else {
                $status = "Non-Compliant"
                $evidence = "Telnet Client is not disabled (State: $($telnetFeature.State))"
            }
        } else {
            # Feature not found might mean it's not available on this edition
            $status = "Compliant"
            $evidence = "Telnet Client feature not found (likely not available on this Windows edition)"
        }
        
        return @{
            RuleID   = "WN11-SO-000025"
            Status   = $status
            Evidence = $evidence
            FixText  = "Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000025"
            Status   = "Error"
            Evidence = "Error checking Telnet Client status: $($_.Exception.Message)"
            FixText  = ""
        }
    }
}

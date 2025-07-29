<#
.SYNOPSIS
    PowerShell 2.0 must be disabled

.DESCRIPTION
    STIG Rule: WN11-SO-000005
    Category: CAT I
    
    PowerShell 2.0 must be disabled

.NOTES
    Generated from DISA STIG documentation
    Rule ID: WN11-SO-000005
    Severity: CAT I
#>

function Test-WN11SO000005 {
    try {
        # Check if PowerShell 2.0 is disabled
        # Based on SCAP: Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root
        
        $psv2Feature = Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -ErrorAction SilentlyContinue
        
        if ($psv2Feature) {
            if ($psv2Feature.State -eq "Disabled") {
                $status = "Compliant"
                $evidence = "PowerShell 2.0 is disabled (State: $($psv2Feature.State))"
            } else {
                $status = "Non-Compliant"
                $evidence = "PowerShell 2.0 is not disabled (State: $($psv2Feature.State))"
            }
        } else {
            # If feature is not found, check registry fallback
            $regPath = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine"
            if (Test-Path $regPath) {
                $status = "Non-Compliant"
                $evidence = "PowerShell 2.0 engine registry entries still exist"
            } else {
                $status = "Compliant"
                $evidence = "PowerShell 2.0 feature not found (likely disabled or removed)"
            }
        }
        
        return @{
            RuleID   = "WN11-SO-000005"
            Status   = $status
            Evidence = $evidence
            FixText  = "Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000005"
            Status   = "Error"
            Evidence = "Error checking compliance: $($_.Exception.Message)"
            FixText  = ""
        }
    }
}

# Example STIG Rule: Disable SMBv1 Protocol
# Rule ID: WN11-SO-000001

function Test-DisableSMBv1 {
    <#
    .SYNOPSIS
        Tests if SMBv1 protocol is disabled on Windows 11
    
    .DESCRIPTION
        Checks the Windows Optional Feature status for SMB1Protocol to ensure it's disabled
        for security compliance with DISA STIG requirements.
    
    .OUTPUTS
        Returns a hashtable with RuleID, Status, Evidence, and FixText
    #>
    
    try {
        $smb = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -ErrorAction Stop
        
        return @{
            RuleID   = "WN11-SO-000001"
            Status   = if ($smb.State -eq "Disabled") { "Compliant" } else { "Non-Compliant" }
            Evidence = "SMB1Protocol State: $($smb.State)"
            FixText  = "Run: Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000001"
            Status   = "Error"
            Evidence = "Error checking SMB1Protocol: $($_.Exception.Message)"
            FixText  = "Manually verify SMB1Protocol feature status"
        }
    }
}

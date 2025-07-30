# STIG Rule: Audit Policy - Logon Events
# Rule ID: WN11-AU-000010
# Category: CAT I (Critical)
# Description: Windows 11 must be configured to audit Account Logon - Logon Events

function Test-AuditLogonEvents {
    <#
    .SYNOPSIS
        Tests if audit policy for logon events is properly configured
    
    .DESCRIPTION
        Checks Windows audit policy to ensure Account Logon - Logon Events
        auditing is enabled for both success and failure events.
        
        STIG Rule: WN11-AU-000010
        Severity: CAT I (Critical)
    
    .OUTPUTS
        Returns a hashtable with RuleID, Status, Evidence, and FixText
    #>
    
    try {
        # Use auditpol to check current audit settings
        $auditResult = auditpol /get /subcategory:"Logon" 2>$null
        
        if ($auditResult) {
            # Parse the output to check if both Success and Failure are enabled
            $logonLine = $auditResult | Where-Object { $_ -like "*Logon*" -and $_ -notlike "*Account Logon*" }
            
            if ($logonLine) {
                $auditSetting = $logonLine.Split("`t")[-1].Trim()
                
                # Check if both Success and Failure are configured
                $isCompliant = $auditSetting -eq "Success and Failure"
                
                return @{
                    RuleID   = "WN11-AU-000010"
                    Status   = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
                    Evidence = "Logon Events audit setting: $auditSetting (Required: Success and Failure)"
                    FixText  = "Configure audit policy: auditpol /set /subcategory:`"Logon`" /success:enable /failure:enable"
                }
            }
        }
        
        # Alternative method using registry if auditpol is not available
        $auditRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security"
        if (Test-Path $auditRegPath) {
            # This is a simplified check - in production, you'd check specific audit registry keys
            return @{
                RuleID   = "WN11-AU-000010"
                Status   = "Non-Compliant"
                Evidence = "Unable to verify logon audit configuration via auditpol"
                FixText  = "Configure audit policy: secpol.msc > Advanced Audit Policy > Logon/Logoff > Audit Logon = Success and Failure"
            }
        }
        
        throw "Unable to access audit policy configuration"
    }
    catch {
        return @{
            RuleID   = "WN11-AU-000010"
            Status   = "Error"
            Evidence = "Error checking audit policy: $($_.Exception.Message)"
            FixText  = "Manually verify audit policy in secpol.msc > Advanced Audit Policy Configuration"
        }
    }
}

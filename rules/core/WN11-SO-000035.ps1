# STIG Rule: Password Policy - Minimum Length
# Rule ID: WN11-SO-000035
# Category: CAT I (Critical)
# Description: The password minimum length must be configured to 14 characters

function Test-PasswordMinimumLength {
    <#
    .SYNOPSIS
        Tests if password minimum length is set to 14 characters or more
    
    .DESCRIPTION
        Checks the system password policy to ensure minimum password length
        meets DISA STIG requirement of 14 characters minimum.
        
        STIG Rule: WN11-SO-000035
        Severity: CAT I (Critical)
    
    .OUTPUTS
        Returns a hashtable with RuleID, Status, Evidence, and FixText
    #>
    
    try {
        # Get password policy using secedit
        $tempFile = [System.IO.Path]::GetTempFileName()
        $null = secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        
        if (Test-Path $tempFile) {
            $content = Get-Content $tempFile
            $minLengthLine = $content | Where-Object { $_ -like "MinimumPasswordLength*" }
            
            if ($minLengthLine) {
                $currentLength = [int]($minLengthLine.Split('=')[1].Trim())
                $isCompliant = $currentLength -ge 14
                
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                
                return @{
                    RuleID   = "WN11-SO-000035"
                    Status   = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
                    Evidence = "Current minimum password length: $currentLength characters (Required: 14+)"
                    FixText  = "Set minimum password length to 14: secpol.msc > Account Policies > Password Policy > Minimum password length = 14"
                }
            }
        }
        
        # Fallback method using PowerShell if secedit fails
        $accountPolicy = Get-WmiObject -Class Win32_AccountPolicy -ErrorAction SilentlyContinue
        if ($accountPolicy) {
            $currentLength = $accountPolicy.MinPasswordLength
            $isCompliant = $currentLength -ge 14
            
            return @{
                RuleID   = "WN11-SO-000035"
                Status   = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
                Evidence = "Current minimum password length: $currentLength characters (Required: 14+)"
                FixText  = "Set minimum password length to 14: secpol.msc > Account Policies > Password Policy > Minimum password length = 14"
            }
        }
        
        throw "Unable to retrieve password policy information"
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000035"
            Status   = "Error"
            Evidence = "Error checking password policy: $($_.Exception.Message)"
            FixText  = "Manually verify password minimum length policy in secpol.msc"
        }
    }
}

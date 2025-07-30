# STIG Rule: Anonymous Access Restrictions
# Rule ID: WN11-SO-000045
# Category: CAT I (Critical)
# Description: Anonymous access to Named Pipes and Shares must be restricted

function Test-AnonymousAccessRestrictions {
    <#
    .SYNOPSIS
        Tests if anonymous access to named pipes and shares is properly restricted
    
    .DESCRIPTION
        Checks registry settings to ensure anonymous access to named pipes and shares
        is restricted according to DISA STIG security requirements.
        
        STIG Rule: WN11-SO-000045
        Severity: CAT I (Critical)
    
    .OUTPUTS
        Returns a hashtable with RuleID, Status, Evidence, and FixText
    #>
    
    try {
        $issues = @()
        $compliantSettings = 0
        $totalSettings = 0
        
        # Check RestrictAnonymous setting
        $restrictAnonymousPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $restrictAnonymous = $null
        
        if (Test-Path $restrictAnonymousPath) {
            $restrictAnonymousValue = Get-ItemProperty -Path $restrictAnonymousPath -Name "RestrictAnonymous" -ErrorAction SilentlyContinue
            $restrictAnonymous = $restrictAnonymousValue.RestrictAnonymous
            $totalSettings++
            
            if ($restrictAnonymous -eq 1) {
                $compliantSettings++
            } else {
                $issues += "RestrictAnonymous: $restrictAnonymous (Required: 1)"
            }
        }
        
        # Check RestrictAnonymousSAM setting
        $restrictAnonymousSAM = $null
        $restrictAnonymousSAMValue = Get-ItemProperty -Path $restrictAnonymousPath -Name "RestrictAnonymousSAM" -ErrorAction SilentlyContinue
        if ($restrictAnonymousSAMValue) {
            $restrictAnonymousSAM = $restrictAnonymousSAMValue.RestrictAnonymousSAM
            $totalSettings++
            
            if ($restrictAnonymousSAM -eq 1) {
                $compliantSettings++
            } else {
                $issues += "RestrictAnonymousSAM: $restrictAnonymousSAM (Required: 1)"
            }
        }
        
        # Check anonymous shares restriction
        $networkAccessPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        $nullSessionShares = $null
        
        if (Test-Path $networkAccessPath) {
            $nullSessionSharesValue = Get-ItemProperty -Path $networkAccessPath -Name "NullSessionShares" -ErrorAction SilentlyContinue
            if ($nullSessionSharesValue) {
                $nullSessionShares = $nullSessionSharesValue.NullSessionShares
                $totalSettings++
                
                # NullSessionShares should be empty or not exist for security
                if (-not $nullSessionShares -or $nullSessionShares.Count -eq 0) {
                    $compliantSettings++
                } else {
                    $issues += "NullSessionShares contains: $($nullSessionShares -join ', ') (Required: Empty)"
                }
            }
        }
        
        # Check anonymous pipes restriction
        $nullSessionPipes = $null
        $nullSessionPipesValue = Get-ItemProperty -Path $networkAccessPath -Name "NullSessionPipes" -ErrorAction SilentlyContinue
        if ($nullSessionPipesValue) {
            $nullSessionPipes = $nullSessionPipesValue.NullSessionPipes
            $totalSettings++
            
            # Some default pipes may be allowed, but the list should be minimal
            $allowedPipes = @("", "netlogon", "lsarpc", "samr")  # Minimal required pipes
            $unauthorizedPipes = $nullSessionPipes | Where-Object { $_ -notin $allowedPipes }
            
            if ($unauthorizedPipes.Count -eq 0) {
                $compliantSettings++
            } else {
                $issues += "Unauthorized NullSessionPipes: $($unauthorizedPipes -join ', ')"
            }
        }
        
        $isCompliant = ($compliantSettings -eq $totalSettings) -and ($issues.Count -eq 0)
        
        if ($isCompliant) {
            $evidence = "All anonymous access restrictions properly configured"
        } else {
            $evidence = "Issues found: $($issues -join '; ')"
        }
        
        return @{
            RuleID   = "WN11-SO-000045"
            Status   = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            Evidence = $evidence
            FixText  = "Configure anonymous access restrictions: secpol.msc > Local Policies > Security Options > Set 'Network access: Restrict anonymous access to Named Pipes and Shares' = Enabled, 'Network access: Do not allow anonymous enumeration of SAM accounts' = Enabled"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000045"
            Status   = "Error"
            Evidence = "Error checking anonymous access restrictions: $($_.Exception.Message)"
            FixText  = "Manually verify anonymous access settings in secpol.msc > Local Policies > Security Options"
        }
    }
}

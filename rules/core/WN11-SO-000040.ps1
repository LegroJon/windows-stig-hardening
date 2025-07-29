# STIG Rule: Remote Desktop Security Settings
# Rule ID: WN11-SO-000040
# Category: CAT I (Critical)
# Description: Remote Desktop Services must be configured to use only FIPS 140-2 validated cryptographic modules

function Test-RemoteDesktopFIPS {
    <#
    .SYNOPSIS
        Tests if Remote Desktop Services uses FIPS 140-2 validated cryptographic modules
    
    .DESCRIPTION
        Checks registry settings to ensure Remote Desktop Services (RDS) is configured
        to use FIPS 140-2 validated cryptographic modules for encryption.
        
        STIG Rule: WN11-SO-000040
        Severity: CAT I (Critical)
    
    .OUTPUTS
        Returns a hashtable with RuleID, Status, Evidence, and FixText
    #>
    
    try {
        # Check if Remote Desktop is enabled first
        $rdpEnabled = $false
        $rdpRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
        
        if (Test-Path $rdpRegPath) {
            $rdpStatus = Get-ItemProperty -Path $rdpRegPath -Name "fDenyTSConnections" -ErrorAction SilentlyContinue
            $rdpEnabled = ($rdpStatus.fDenyTSConnections -eq 0)
        }
        
        if (-not $rdpEnabled) {
            return @{
                RuleID   = "WN11-SO-000040"
                Status   = "Compliant"
                Evidence = "Remote Desktop Services is disabled (fDenyTSConnections = 1)"
                FixText  = "N/A - Remote Desktop is already disabled"
            }
        }
        
        # Check FIPS compliance for RDP
        $fipsRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy"
        $fipsEnabled = $false
        
        if (Test-Path $fipsRegPath) {
            $fipsPolicy = Get-ItemProperty -Path $fipsRegPath -Name "Enabled" -ErrorAction SilentlyContinue
            $fipsEnabled = ($fipsPolicy.Enabled -eq 1)
        }
        
        # Check RDP-specific encryption settings
        $rdpEncryptionPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $encryptionLevel = 0
        
        if (Test-Path $rdpEncryptionPath) {
            $encryptionSetting = Get-ItemProperty -Path $rdpEncryptionPath -Name "MinEncryptionLevel" -ErrorAction SilentlyContinue
            $encryptionLevel = $encryptionSetting.MinEncryptionLevel
        }
        
        # FIPS mode and high encryption level (3 or 4) required
        $isCompliant = $fipsEnabled -and ($encryptionLevel -ge 3)
        
        $evidence = "FIPS Enabled: $fipsEnabled, RDP Encryption Level: $encryptionLevel (Required: FIPS=True, Encryption>=3)"
        $fixText = "Enable FIPS: secpol.msc > Local Policies > Security Options > 'System cryptography: Use FIPS compliant algorithms' = Enabled. Set RDP encryption: gpedit.msc > Computer Configuration > Administrative Templates > Windows Components > Remote Desktop Services > Remote Desktop Session Host > Security > 'Set client connection encryption level' = High Level"
        
        return @{
            RuleID   = "WN11-SO-000040"
            Status   = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            Evidence = $evidence
            FixText  = $fixText
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000040"
            Status   = "Error"
            Evidence = "Error checking Remote Desktop FIPS configuration: $($_.Exception.Message)"
            FixText  = "Manually verify RDP FIPS compliance in Group Policy and Registry settings"
        }
    }
}

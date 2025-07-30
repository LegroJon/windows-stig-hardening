<#
.SYNOPSIS
    Windows Defender Real-time Protection

.DESCRIPTION
    STIG Rule: WN11-SO-000030
    Category: CAT II
    
    Windows Defender Real-time Protection

.NOTES
    Generated from DISA STIG documentation
    Rule ID: WN11-SO-000030
    Severity: CAT II
#>

function Test-WN11SO000030 {
    try {
        # Check Windows Defender Real-time Protection status
        # Real-time protection should be enabled for malware protection
        
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        
        if ($defenderStatus) {
            $realTimeProtection = $defenderStatus.RealTimeProtectionEnabled
            $antivirusEnabled = $defenderStatus.AntivirusEnabled
            $antispywareEnabled = $defenderStatus.AntispywareEnabled
            
            if ($realTimeProtection -and $antivirusEnabled -and $antispywareEnabled) {
                $status = "Compliant"
                $evidence = "Windows Defender real-time protection is enabled (RealTime: $realTimeProtection, Antivirus: $antivirusEnabled, Antispyware: $antispywareEnabled)"
            } else {
                $status = "Non-Compliant"
                $evidence = "Windows Defender real-time protection is not fully enabled (RealTime: $realTimeProtection, Antivirus: $antivirusEnabled, Antispyware: $antispywareEnabled)"
            }
        } else {
            # Fallback to registry check
            try {
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection"
                if (Test-Path $regPath) {
                    $disableRealTimeMonitoring = Get-ItemProperty -Path $regPath -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
                    
                    if ($disableRealTimeMonitoring.DisableRealtimeMonitoring -eq 0) {
                        $status = "Compliant"
                        $evidence = "Windows Defender real-time monitoring is enabled (Registry check)"
                    } else {
                        $status = "Non-Compliant"
                        $evidence = "Windows Defender real-time monitoring is disabled (Registry value: $($disableRealTimeMonitoring.DisableRealtimeMonitoring))"
                    }
                } else {
                    $status = "Error"
                    $evidence = "Cannot determine Windows Defender status - registry path not found"
                }
            }
            catch {
                $status = "Error"
                $evidence = "Registry check failed: $($_.Exception.Message)"
            }
        }
        
        return @{
            RuleID   = "WN11-SO-000030"
            Status   = $status
            Evidence = $evidence
            FixText  = "Enable Windows Defender: Windows Security > Virus & threat protection > Virus & threat protection settings > Real-time protection (Turn on)"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000030"
            Status   = "Error"
            Evidence = "Error checking Windows Defender status: $($_.Exception.Message)"
            FixText  = ""
        }
    }
}

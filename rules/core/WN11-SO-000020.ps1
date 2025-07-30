<#
.SYNOPSIS
    BitLocker Drive Encryption

.DESCRIPTION
    STIG Rule: WN11-SO-000020
    Category: CAT I
    
    BitLocker Drive Encryption

.NOTES
    Generated from DISA STIG documentation
    Rule ID: WN11-SO-000020
    Severity: CAT I
#>

function Test-WN11SO000020 {
    try {
        # Check BitLocker Drive Encryption status
        # System drive should be encrypted with BitLocker
        
        $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
        
        if ($bitlockerStatus) {
            $protectionStatus = $bitlockerStatus.ProtectionStatus
            $encryptionPercentage = $bitlockerStatus.EncryptionPercentage
            $volumeStatus = $bitlockerStatus.VolumeStatus
            
            if ($protectionStatus -eq "On" -and $encryptionPercentage -eq 100) {
                $status = "Compliant"
                $evidence = "BitLocker is enabled and fully encrypted (Protection: $protectionStatus, Encryption: $encryptionPercentage%, Status: $volumeStatus)"
            } elseif ($protectionStatus -eq "On" -and $encryptionPercentage -lt 100) {
                $status = "Non-Compliant"
                $evidence = "BitLocker is enabled but encryption is incomplete (Protection: $protectionStatus, Encryption: $encryptionPercentage%, Status: $volumeStatus)"
            } else {
                $status = "Non-Compliant"
                $evidence = "BitLocker is not properly enabled (Protection: $protectionStatus, Encryption: $encryptionPercentage%, Status: $volumeStatus)"
            }
        } else {
            # Fallback to WMI if Get-BitLockerVolume fails
            try {
                $wmiQuery = Get-WmiObject -Namespace "Root\CIMV2\Security\MicrosoftVolumeEncryption" -Class "Win32_EncryptableVolume" -Filter "DriveLetter='C:'"
                if ($wmiQuery) {
                    $conversionStatus = $wmiQuery.ConversionStatus
                    if ($conversionStatus -eq 1) {
                        $status = "Compliant"
                        $evidence = "BitLocker is fully encrypted (WMI ConversionStatus: $conversionStatus)"
                    } else {
                        $status = "Non-Compliant"
                        $evidence = "BitLocker encryption incomplete or disabled (WMI ConversionStatus: $conversionStatus)"
                    }
                } else {
                    $status = "Non-Compliant"
                    $evidence = "BitLocker not available or not configured on system drive"
                }
            }
            catch {
                $status = "Error"
                $evidence = "Unable to determine BitLocker status: $($_.Exception.Message)"
            }
        }
        
        return @{
            RuleID   = "WN11-SO-000020"
            Status   = $status
            Evidence = $evidence
            FixText  = "Enable BitLocker: Control Panel > System and Security > BitLocker Drive Encryption > Turn on BitLocker for the system drive. Follow the wizard to configure encryption and recovery options."
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000020"
            Status   = "Error"
            Evidence = "Error checking BitLocker status: $($_.Exception.Message)"
            FixText  = ""
        }
    }
}

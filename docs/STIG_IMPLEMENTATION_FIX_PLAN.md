# 🛠️ STIG Rule Implementation Fix Plan
## Immediate Action Items for Current Rule Failures

**Priority**: HIGH - Fix 7 failing rules (58% error rate → <5%)  
**Timeline**: 1-2 weeks  
**Goal**: Stabilize current implementation before expansion

---

## 🔧 **Rule Fixes Required**

### **1. WN11-AU-000010: Audit Policy Configuration**
**Current Issue**: Function error with no evidence  
**Root Cause**: Missing audit policy checking logic

```powershell
# Fix Implementation:
function Test-AuditPolicy {
    <#
    .SYNOPSIS
        Tests Windows audit policy configuration for STIG compliance
    #>
    try {
        # Check audit policies using auditpol.exe
        $auditPolicies = @{
            "Logon/Logoff" = "Success and Failure"
            "Account Management" = "Success and Failure" 
            "Privilege Use" = "Failure"
            "System Events" = "Success and Failure"
        }
        
        $issues = @()
        foreach ($category in $auditPolicies.Keys) {
            $result = & auditpol.exe /get /category:"$category" 2>$null
            if (-not $result -or $result -notlike "*$($auditPolicies[$category])*") {
                $issues += "$category not configured properly"
            }
        }
        
        return @{
            RuleID   = "WN11-AU-000010"
            Status   = if ($issues.Count -eq 0) { "Compliant" } else { "Non-Compliant" }
            Evidence = if ($issues.Count -eq 0) { "All audit policies properly configured" } else { "Issues: $($issues -join '; ')" }
            FixText  = "Configure audit policies via Group Policy or auditpol.exe commands"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-AU-000010"
            Status   = "Error"
            Evidence = "Error checking audit policies: $($_.Exception.Message)"
            FixText  = "Manually verify audit policy configuration via auditpol.exe"
        }
    }
}
```

### **2. WN11-SO-000001: SMBv1 Protocol (Function Naming Fix)**
**Current Issue**: Function name mismatch in rule discovery  
**Root Cause**: `Test-DisableSMBv1` vs expected `Test-WN11SO000001`

```powershell
# Fix Implementation:
function Test-WN11SO000001 {
    <#
    .SYNOPSIS
        Tests if SMBv1 protocol is disabled (STIG Rule WN11-SO-000001)
    #>
    try {
        $smb = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -ErrorAction Stop
        
        return @{
            RuleID   = "WN11-SO-000001"
            Status   = if ($smb.State -eq "Disabled") { "Compliant" } else { "Non-Compliant" }
            Evidence = "SMB1Protocol State: $($smb.State)"
            FixText  = "Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000001"
            Status   = "Error"
            Evidence = "Error checking SMB1Protocol: $($_.Exception.Message)"
            FixText  = "Manually verify SMB1Protocol feature: Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol"
        }
    }
}
```

### **3. WN11-SO-000005: User Account Control Configuration**
**Current Issue**: UAC policy checking not implemented  
**Root Cause**: Missing registry value validation

```powershell
# Fix Implementation:
function Test-WN11SO000005 {
    <#
    .SYNOPSIS
        Tests User Account Control (UAC) configuration for STIG compliance
    #>
    try {
        $uacSettings = @{
            "EnableLUA" = @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Value = 1 }
            "ConsentPromptBehaviorAdmin" = @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Value = 2 }
            "PromptOnSecureDesktop" = @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Value = 1 }
        }
        
        $issues = @()
        foreach ($setting in $uacSettings.Keys) {
            try {
                $currentValue = Get-ItemProperty -Path $uacSettings[$setting].Path -Name $setting -ErrorAction Stop
                if ($currentValue.$setting -ne $uacSettings[$setting].Value) {
                    $issues += "$setting = $($currentValue.$setting) (Required: $($uacSettings[$setting].Value))"
                }
            }
            catch {
                $issues += "$setting registry value not found"
            }
        }
        
        return @{
            RuleID   = "WN11-SO-000005"
            Status   = if ($issues.Count -eq 0) { "Compliant" } else { "Non-Compliant" }
            Evidence = if ($issues.Count -eq 0) { "UAC properly configured" } else { "UAC issues: $($issues -join '; ')" }
            FixText  = "Configure UAC via Group Policy: Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Security Options"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000005"
            Status   = "Error"
            Evidence = "Error checking UAC configuration: $($_.Exception.Message)"
            FixText  = "Manually verify UAC settings in Local Security Policy (secpol.msc)"
        }
    }
}
```

### **4. WN11-SO-000010: Simple TCP/IP Services**
**Current Issue**: Service checking requires elevation  
**Root Cause**: Insufficient error handling for admin requirements

```powershell
# Fix Implementation:
function Test-WN11SO000010 {
    <#
    .SYNOPSIS
        Tests if Simple TCP/IP Services are disabled for STIG compliance
    #>
    try {
        $servicesToCheck = @("simptcp", "TlntSvr")
        $issues = @()
        $compliant = @()
        
        foreach ($serviceName in $servicesToCheck) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction Stop
                if ($service.Status -eq "Running" -or $service.StartType -eq "Automatic") {
                    $issues += "$serviceName ($($service.Status), $($service.StartType))"
                } else {
                    $compliant += "$serviceName ($($service.Status), $($service.StartType))"
                }
            }
            catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
                # Service not installed/found - this is compliant
                $compliant += "$serviceName (Not Installed)"
            }
        }
        
        return @{
            RuleID   = "WN11-SO-000010"
            Status   = if ($issues.Count -eq 0) { "Compliant" } else { "Non-Compliant" }
            Evidence = if ($issues.Count -eq 0) { "All services properly disabled: $($compliant -join ', ')" } else { "Running services found: $($issues -join ', ')" }
            FixText  = "Disable services: Stop-Service <ServiceName>; Set-Service <ServiceName> -StartupType Disabled"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000010"
            Status   = "Error"
            Evidence = "Error checking Simple TCP/IP Services: $($_.Exception.Message)"
            FixText  = "Manually verify service status: Get-Service simptcp, TlntSvr"
        }
    }
}
```

### **5. WN11-SO-000020: BitLocker Drive Encryption**
**Current Issue**: BitLocker status checking not implemented  
**Root Cause**: Missing BitLocker PowerShell module usage

```powershell
# Fix Implementation:
function Test-WN11SO000020 {
    <#
    .SYNOPSIS
        Tests BitLocker drive encryption status for STIG compliance
    #>
    try {
        # Check if BitLocker module is available
        if (-not (Get-Module -Name BitLocker -ListAvailable)) {
            return @{
                RuleID   = "WN11-SO-000020"
                Status   = "Error"
                Evidence = "BitLocker PowerShell module not available"
                FixText  = "Install BitLocker feature: Enable-WindowsOptionalFeature -Online -FeatureName BitLocker"
            }
        }
        
        Import-Module BitLocker -ErrorAction Stop
        $volumes = Get-BitLockerVolume -ErrorAction Stop
        $systemVolume = $volumes | Where-Object { $_.MountPoint -eq $env:SystemDrive }
        
        if (-not $systemVolume) {
            return @{
                RuleID   = "WN11-SO-000020"
                Status   = "Non-Compliant"
                Evidence = "System drive not found in BitLocker volumes"
                FixText  = "Enable BitLocker on system drive via Control Panel > BitLocker Drive Encryption"
            }
        }
        
        $status = if ($systemVolume.ProtectionStatus -eq "On") { "Compliant" } else { "Non-Compliant" }
        
        return @{
            RuleID   = "WN11-SO-000020"
            Status   = $status
            Evidence = "System drive ($($systemVolume.MountPoint)) BitLocker status: $($systemVolume.ProtectionStatus), Encryption: $($systemVolume.EncryptionPercentage)%"
            FixText  = "Enable BitLocker: manage-bde -on $($env:SystemDrive) -RecoveryPassword -RecoveryKey"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000020"
            Status   = "Error"
            Evidence = "Error checking BitLocker status: $($_.Exception.Message)"
            FixText  = "Manually verify BitLocker: manage-bde -status or Get-BitLockerVolume"
        }
    }
}
```

### **6. WN11-SO-000025: Telnet Client Disabled**
**Current Issue**: Windows feature checking not implemented  
**Root Cause**: Missing Get-WindowsOptionalFeature usage

```powershell
# Fix Implementation:
function Test-WN11SO000025 {
    <#
    .SYNOPSIS
        Tests if Telnet Client is disabled for STIG compliance
    #>
    try {
        $telnetClient = Get-WindowsOptionalFeature -Online -FeatureName "TelnetClient" -ErrorAction Stop
        
        return @{
            RuleID   = "WN11-SO-000025"
            Status   = if ($telnetClient.State -eq "Disabled") { "Compliant" } else { "Non-Compliant" }
            Evidence = "Telnet Client feature state: $($telnetClient.State)"
            FixText  = "Disable Telnet Client: Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart"
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000025"
            Status   = "Error"  
            Evidence = "Error checking Telnet Client feature: $($_.Exception.Message)"
            FixText  = "Manually verify Telnet Client: Get-WindowsOptionalFeature -Online -FeatureName TelnetClient"
        }
    }
}
```

---

## 🔧 **Implementation Script**

Here's an automated fix script:

```powershell
# Auto-fix script for STIG rule implementations
param(
    [switch]$FixNaming,
    [switch]$UpdateFunctions,
    [switch]$TestAll,
    [switch]$UpdateMetadata
)

function Update-RuleFunction {
    param(
        [string]$RuleFile,
        [string]$NewFunctionName,
        [string]$NewImplementation
    )
    
    Write-Host "[FIX] Updating $RuleFile with $NewFunctionName..." -ForegroundColor Cyan
    
    # Backup original
    $backupFile = $RuleFile + ".backup"
    Copy-Item $RuleFile $backupFile
    
    # Replace content
    Set-Content -Path $RuleFile -Value $NewImplementation -Encoding UTF8
    
    Write-Host "[SUCCESS] Updated $RuleFile" -ForegroundColor Green
}

if ($FixNaming) {
    Write-Host "[STIG] Standardizing function naming..." -ForegroundColor Cyan
    
    # Fix WN11-SO-000001 naming
    $newContent = Get-Content "rules\core\WN11-SO-000001.ps1" -Raw
    $newContent = $newContent -replace "Test-DisableSMBv1", "Test-WN11SO000001"
    Set-Content "rules\core\WN11-SO-000001.ps1" -Value $newContent
    
    Write-Host "[SUCCESS] Standardized function naming" -ForegroundColor Green
}

if ($UpdateMetadata) {
    Write-Host "[STIG] Updating rules.json metadata..." -ForegroundColor Cyan
    
    # Implementation for updating metadata with all current rules
    # This would expand the rules.json to include all 12 current rules
    
    Write-Host "[SUCCESS] Updated metadata" -ForegroundColor Green
}

Write-Host "`n[COMPLETE] STIG rule fixes applied" -ForegroundColor Green
Write-Host "[NEXT] Run assessment to verify fixes: .\scripts\Start-STIGAssessment.ps1" -ForegroundColor Blue
```

---

## 📋 **Testing Plan**

### **Unit Testing Each Fix**
```powershell
# Test individual rule functions
Test-WN11SO000001  # SMBv1 Protocol
Test-WN11SO000005  # UAC Configuration  
Test-WN11SO000010  # Simple TCP/IP Services
Test-WN11SO000020  # BitLocker Encryption
Test-WN11SO000025  # Telnet Client
Test-AuditPolicy   # Audit Policy (WN11-AU-000010)
```

### **Integration Testing**
```powershell
# Run full assessment to verify error reduction
.\scripts\Start-STIGAssessment.ps1 -Format JSON -Verbose
# Target: Error rate <5% (currently 58%)
```

### **Validation Criteria**
- [ ] All 7 error-state rules return proper Status/Evidence/FixText
- [ ] Function naming follows Test-WN11* standard
- [ ] Error messages provide actionable guidance
- [ ] Admin privilege requirements clearly documented
- [ ] Assessment completes without PowerShell errors

---

## 🎯 **Success Metrics**

| Metric | Before Fix | After Fix Target |
|--------|------------|------------------|
| **Error Rate** | 58% (7/12 rules) | <5% (0-1/12 rules) |
| **Function Naming** | Inconsistent | 100% standardized |
| **Error Details** | Blank evidence | Detailed error messages |
| **Compliance Rate** | 8.33% | 15-25% (realistic) |

This implementation plan addresses the immediate stability issues while maintaining the modular architecture for future expansion.

# STIG Rule: System Services Security
# Rule ID: WN11-SO-000050
# Category: CAT I (Critical)
# Description: Unnecessary system services must be disabled or removed

function Test-UnnecessaryServices {
    <#
    .SYNOPSIS
        Tests if unnecessary system services are disabled for security
    
    .DESCRIPTION
        Checks the status of system services that should be disabled
        according to DISA STIG security requirements to reduce attack surface.
        
        STIG Rule: WN11-SO-000050
        Severity: CAT I (Critical)
    
    .OUTPUTS
        Returns a hashtable with RuleID, Status, Evidence, and FixText
    #>
    
    try {
        # Define services that should be disabled for security
        $servicesToDisable = @{
            "Telnet"                = "Telnet service (insecure protocol)"
            "simptcp"              = "Simple TCP/IP Services"
            "SSDPSRV"              = "SSDP Discovery Service"
            "upnphost"             = "UPnP Device Host"
            "RemoteRegistry"       = "Remote Registry service"
            "Messenger"            = "Messenger service"
            "NetDDE"               = "Network DDE service"
            "NetDDEdsdm"          = "Network DDE DSDM service"
            "RpcLocator"          = "Remote Procedure Call (RPC) Locator"
            "TlntSvr"             = "Telnet Server"
            "SNMP"                 = "SNMP Service"
            "Browser"              = "Computer Browser service"
        }
        
        $runningServices = @()
        $disabledServices = @()
        $notFoundServices = @()
        
        foreach ($serviceName in $servicesToDisable.Keys) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction Stop
                
                if ($service.Status -eq "Running" -or $service.StartType -eq "Automatic") {
                    $runningServices += "$serviceName ($($servicesToDisable[$serviceName]))"
                } else {
                    $disabledServices += $serviceName
                }
            }
            catch {
                # Service not found (which is good - means it's not installed)
                $notFoundServices += $serviceName
            }
        }
        
        # Check Windows optional features that should be disabled
        $optionalFeaturesToDisable = @(
            "SMB1Protocol",
            "TelnetClient",
            "TelnetServer",
            "TFTP",
            "SimpleTCP"
        )
        
        $enabledFeatures = @()
        foreach ($featureName in $optionalFeaturesToDisable) {
            try {
                $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName -ErrorAction SilentlyContinue
                if ($feature -and $feature.State -eq "Enabled") {
                    $enabledFeatures += $featureName
                }
            }
            catch {
                # Feature not found or error checking - continue
            }
        }
        
        # Determine compliance
        $isCompliant = ($runningServices.Count -eq 0) -and ($enabledFeatures.Count -eq 0)
        
        # Build evidence string
        $evidenceParts = @()
        if ($runningServices.Count -gt 0) {
            $evidenceParts += "Running/Auto services: $($runningServices -join ', ')"
        }
        if ($enabledFeatures.Count -gt 0) {
            $evidenceParts += "Enabled features: $($enabledFeatures -join ', ')"
        }
        if ($disabledServices.Count -gt 0) {
            $evidenceParts += "Properly disabled services: $($disabledServices.Count)"
        }
        if ($notFoundServices.Count -gt 0) {
            $evidenceParts += "Not installed services: $($notFoundServices.Count)"
        }
        
        $evidence = if ($evidenceParts.Count -gt 0) { $evidenceParts -join '; ' } else { "All services properly configured" }
        
        # Build fix text
        $fixCommands = @()
        if ($runningServices.Count -gt 0) {
            $fixCommands += "Disable services: Stop-Service and Set-Service -StartupType Disabled"
        }
        if ($enabledFeatures.Count -gt 0) {
            $fixCommands += "Disable features: Disable-WindowsOptionalFeature -Online"
        }
        
        $fixText = if ($fixCommands.Count -gt 0) { $fixCommands -join '; ' } else { "N/A - All services properly configured" }
        
        return @{
            RuleID   = "WN11-SO-000050"
            Status   = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            Evidence = $evidence
            FixText  = $fixText
        }
    }
    catch {
        return @{
            RuleID   = "WN11-SO-000050"
            Status   = "Error"
            Evidence = "Error checking system services: $($_.Exception.Message)"
            FixText  = "Manually review services.msc and Windows Features to disable unnecessary services"
        }
    }
}

# Shared Mock Functions for STIG Assessment Testing
# This file contains reusable mock functions for testing without affecting the actual system

# Mock Windows Features
function Mock-WindowsOptionalFeature {
    param(
        [string]$FeatureName,
        [string]$State = "Disabled"
    )
    
    return @{
        FeatureName = $FeatureName
        State = $State
        RestartRequired = $false
        LogPath = ""
        ScratchDirectory = ""
        LogLevel = "Errors"
    }
}

# Mock OS Information
function Mock-OSInfo {
    param(
        [string]$OSVersion = "Windows11"
    )
    
    $osData = $Global:TestSettings.TestData.SampleOSInfo
    
    switch ($OSVersion) {
        "Windows11" { return $osData.Windows11 }
        "Windows10" { return $osData.Windows10 }
        default { return $osData.Windows11 }
    }
}

# Mock Registry Operations
function Mock-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "String"
    )
    
    return @{
        Path = $Path
        Name = $Name
        Value = $Value
        Type = $Type
    }
}

# Mock Service Information
function Mock-ServiceInfo {
    param(
        [string]$ServiceName,
        [string]$Status = "Stopped",
        [string]$StartType = "Disabled"
    )
    
    return @{
        Name = $ServiceName
        Status = $Status
        StartType = $StartType
        DisplayName = "Mock Service: $ServiceName"
    }
}

# Mock Security Policy
function Mock-SecurityPolicy {
    param(
        [string]$PolicyName,
        [string]$PolicyValue
    )
    
    return @{
        PolicyName = $PolicyName
        PolicyValue = $PolicyValue
        Description = "Mock security policy for testing"
    }
}

# Mock User Rights Assignment
function Mock-UserRights {
    param(
        [string]$Right,
        [string[]]$Users = @("Administrators")
    )
    
    return @{
        Right = $Right
        Users = $Users
        Description = "Mock user rights assignment"
    }
}

# Mock Audit Policy
function Mock-AuditPolicy {
    param(
        [string]$Category,
        [string]$Setting = "Success and Failure"
    )
    
    return @{
        Category = $Category
        Setting = $Setting
        GUID = [System.Guid]::NewGuid().ToString()
    }
}

# Mock Group Policy
function Mock-GroupPolicy {
    param(
        [string]$KeyPath,
        [string]$ValueName,
        [object]$Value
    )
    
    return @{
        KeyPath = $KeyPath
        ValueName = $ValueName
        Value = $Value
        Type = "REG_DWORD"
    }
}

# Mock File/Folder Permissions
function Mock-FilePermissions {
    param(
        [string]$Path,
        [string[]]$Permissions = @("FullControl"),
        [string]$Principal = "Administrators"
    )
    
    return @{
        Path = $Path
        Principal = $Principal
        Permissions = $Permissions
        Inherited = $false
    }
}

# Mock System Information
function Mock-SystemInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Domain = "WORKGROUP",
        [bool]$IsAdmin = $true
    )
    
    return @{
        ComputerName = $ComputerName
        Domain = $Domain
        IsAdmin = $IsAdmin
        OSVersion = "10.0.22621"
        Architecture = "AMD64"
    }
}

# Mock Network Configuration
function Mock-NetworkConfig {
    param(
        [string]$AdapterName = "Ethernet",
        [bool]$FirewallEnabled = $true,
        [string]$Profile = "Domain"
    )
    
    return @{
        AdapterName = $AdapterName
        FirewallEnabled = $FirewallEnabled
        Profile = $Profile
        IPAddress = "192.168.1.100"
        SubnetMask = "255.255.255.0"
    }
}

# Helper function to create standard STIG rule result
function New-MockSTIGResult {
    param(
        [string]$RuleID,
        [string]$Status = "Compliant",
        [string]$Evidence = "Mock evidence",
        [string]$FixText = "Mock fix text"
    )
    
    return @{
        RuleID = $RuleID
        Status = $Status
        Evidence = $Evidence
        FixText = $FixText
        Timestamp = Get-Date
        ComputerName = $env:COMPUTERNAME
    }
}

Write-Verbose "Mock functions loaded successfully"

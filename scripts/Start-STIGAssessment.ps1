<#
.SYNOPSIS
    Windows 11 STIG Assessment Tool - Main CLI Entry Point

.DESCRIPTION
    A modular PowerShell tool for assessing DISA STIG compliance on Windows 11 systems.
    This tool performs detection and assessment without making system changes, providing 
    detailed compliance reports with remediation guidance.

.PARAMETER OutputPath
    Specify custom output directory for reports. Default: ./reports

.PARAMETER ConfigPath
    Path to custom configuration file. Default: ./config/settings.json

.PARAMETER IncludeCustomRules
    Include custom organizational rules in assessment

.PARAMETER Format
    Report output format. Options: JSON, HTML, CSV. Default: JSON

.PARAMETER RuleFilter
    Filter rules by category or severity. Examples: "CAT I", "SO", "WN11-SO-000001"

.PARAMETER LogLevel
    Logging verbosity. Options: ERROR, WARN, INFO, DEBUG. Default: INFO

.PARAMETER WhatIf
    Show what would be assessed without running actual checks

.PARAMETER RequestAdmin
    Automatically request administrator privileges if not already elevated

.EXAMPLE
    .\Start-STIGAssessment.ps1
    Run basic STIG assessment with default settings

.EXAMPLE
    .\Start-STIGAssessment.ps1 -OutputPath "C:\Reports" -Format HTML
    Run assessment with custom output location and HTML report

.EXAMPLE
    .\Start-STIGAssessment.ps1 -RuleFilter "CAT I" -LogLevel DEBUG
    Run only Category I rules with debug logging

.NOTES
    Author: Jonathan Legro
    Version: 1.0.0
    Requires: PowerShell 5.1+ and Administrator privileges
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ConfigPath = ".\config\settings.json",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeCustomRules,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "HTML", "CSV")]
    [string]$Format,

    [Parameter(Mandatory = $false)]
    [string]$RuleFilter,

    [Parameter(Mandatory = $false)]
    [ValidateSet("ERROR", "WARN", "INFO", "DEBUG")]
    [string]$LogLevel,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [switch]$RequestAdmin
)

# Set error handling
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Check for administrator privileges and request if needed
function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($RequestAdmin -and -not (Test-IsAdministrator)) {
    Write-Host "`n🛡️ Requesting Administrator Privileges..." -ForegroundColor Yellow
    Write-Host "Some STIG checks require elevated privileges for accurate assessment." -ForegroundColor Gray
    
    try {
        # Build argument list for elevated session
        $argList = @(
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$PSCommandPath`""
        )
        
        # Add original parameters (excluding RequestAdmin to avoid recursion)
        if ($OutputPath) { $argList += "-OutputPath", "`"$OutputPath`"" }
        if ($ConfigPath -ne ".\config\settings.json") { $argList += "-ConfigPath", "`"$ConfigPath`"" }
        if ($IncludeCustomRules) { $argList += "-IncludeCustomRules" }
        if ($Format) { $argList += "-Format", $Format }
        if ($RuleFilter) { $argList += "-RuleFilter", "`"$RuleFilter`"" }
        if ($LogLevel) { $argList += "-LogLevel", $LogLevel }
        if ($WhatIf) { $argList += "-WhatIf" }
        
        Start-Process -FilePath "PowerShell.exe" -Verb RunAs -ArgumentList $argList
        Write-Host "Elevated session started. This window will close." -ForegroundColor Green
        exit 0
    }
    catch {
        Write-Host "[ERROR] Failed to request elevation: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Continuing with current privileges (some checks may be limited)..." -ForegroundColor Yellow
    }
}

#region Helper Functions

function Write-STIGLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("ERROR", "WARN", "INFO", "DEBUG")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [switch]$ToHost
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Output to console based on level
    if ($ToHost -or $script:Config.logging.log_to_console) {
        switch ($Level) {
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
            "INFO"  { Write-Host $logEntry -ForegroundColor Green }
            "DEBUG" { Write-Host $logEntry -ForegroundColor Gray }
        }
    }
    
    # TODO: Implement file logging
    Write-Verbose $logEntry
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-SystemRequirements {
    Write-STIGLog "Checking system requirements..." -Level INFO
    
    # Check Windows version
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    if ($osInfo.Caption -notlike "*Windows 11*") {
        throw "This tool requires Windows 11. Detected: $($osInfo.Caption)"
    }
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    $minVersion = [Version]"5.1"
    if ($psVersion -lt $minVersion) {
        throw "PowerShell version $minVersion or higher required. Current: $psVersion"
    }
    
    # Check admin privileges
    if ($script:Config.system.require_admin -and -not (Test-AdminPrivileges)) {
        throw "Administrator privileges required. Please run as Administrator."
    }
    
    Write-STIGLog "System requirements check passed" -Level INFO
}

function Import-Configuration {
    param([string]$Path)
    
    Write-STIGLog "Loading configuration from: $Path" -Level INFO
    
    if (-not (Test-Path $Path)) {
        throw "Configuration file not found: $Path"
    }
    
    try {
        $config = Get-Content $Path -Raw | ConvertFrom-Json
        Write-STIGLog "Configuration loaded successfully" -Level INFO
        return $config
    }
    catch {
        throw "Failed to parse configuration file: $($_.Exception.Message)"
    }
}

function Get-STIGRules {
    param(
        [string]$RulesPath,
        [string]$Filter
    )
    
    Write-STIGLog "Discovering STIG rules in: $RulesPath" -Level INFO
    
    if (-not (Test-Path $RulesPath)) {
        Write-STIGLog "Rules directory not found: $RulesPath" -Level WARN
        return @()
    }
    
    $ruleFiles = Get-ChildItem -Path $RulesPath -Filter "*.ps1" -File
    Write-STIGLog "Found $($ruleFiles.Count) rule files" -Level INFO
    
    return $ruleFiles
}

function Show-AssessmentSummary {
    param(
        [hashtable]$Config,
        [array]$Rules,
        [string]$OutputPath
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "🛡️  Windows 11 STIG Assessment Tool" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "Assessment: " -NoNewline -ForegroundColor White
    Write-Host $Config.assessment.name -ForegroundColor Green
    Write-Host "Version:    " -NoNewline -ForegroundColor White
    Write-Host $Config.assessment.version -ForegroundColor Green
    Write-Host "Rules:      " -NoNewline -ForegroundColor White
    Write-Host "$($Rules.Count) rules discovered" -ForegroundColor Green
    Write-Host "Output:     " -NoNewline -ForegroundColor White
    Write-Host $OutputPath -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host ""
}

#endregion

#region Main Execution

try {
    # Load configuration
    $script:Config = Import-Configuration -Path $ConfigPath
    
    # Override config with parameters
    if ($LogLevel) { $script:Config.logging.level = $LogLevel }
    if ($Format) { $script:Config.reporting.default_format = $Format }
    if ($IncludeCustomRules) { $script:Config.scanning.include_custom_rules = $true }
    
    # Set output path
    if (-not $OutputPath) {
        $OutputPath = $script:Config.output.reports_directory
    }
    
    # Create output directory if needed
    if ($script:Config.output.create_directories -and -not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-STIGLog "Created output directory: $OutputPath" -Level INFO
    }
    
    # Check system requirements
    Test-SystemRequirements
    
    # Discover rules
    $coreRules = Get-STIGRules -RulesPath $script:Config.rules.core_rules_path
    $customRules = @()
    
    if ($script:Config.scanning.include_custom_rules) {
        $customRules = Get-STIGRules -RulesPath $script:Config.rules.custom_rules_path
    }
    
    $allRules = $coreRules + $customRules
    
    if ($allRules.Count -eq 0) {
        throw "No STIG rules found. Check rules directories."
    }
    
    # Show assessment summary
    Show-AssessmentSummary -Config $script:Config -Rules $allRules -OutputPath $OutputPath
    
    if ($WhatIf) {
        Write-STIGLog "WhatIf mode - Assessment preview completed" -Level INFO
        Write-Host "Assessment would process $($allRules.Count) rules" -ForegroundColor Yellow
        return
    }
    
    # TODO: Implement rule execution engine
    Write-STIGLog "Rule execution engine not yet implemented" -Level WARN
    Write-Host "⚠️  Core functionality coming soon!" -ForegroundColor Yellow
    Write-Host "   - Rule execution engine" -ForegroundColor Gray
    Write-Host "   - Report generation" -ForegroundColor Gray
    Write-Host "   - Results analysis" -ForegroundColor Gray
    
    Write-STIGLog "Assessment preparation completed successfully" -Level INFO
    
} catch {
    Write-STIGLog "Assessment failed: $($_.Exception.Message)" -Level ERROR -ToHost
    exit 1
}

#endregion

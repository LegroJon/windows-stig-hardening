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
    Report output format. Options: JSON, HTML, CSV, ALL. Can specify multiple formats. Default: JSON

.PARAMETER RuleFilter
    Filter rules by category or severity. Examples: "CAT I", "SO", "WN11-SO-000001"

.PARAMETER LogLevel
    Logging verbosity. Options: ERROR, WARN, INFO, DEBUG. Default: INFO

.PARAMETER RequestAdmin
    Automatically request administrator privileges if not already elevated

.EXAMPLE
    .\Start-STIGAssessment.ps1
    Run basic STIG assessment with default settings

.EXAMPLE
    .\Start-STIGAssessment.ps1 -OutputPath "C:\Reports" -Format HTML
    Run assessment with custom output location and HTML report

.EXAMPLE
    .\Start-STIGAssessment.ps1 -Format HTML,CSV
    Generate both HTML and CSV reports

.EXAMPLE
    .\Start-STIGAssessment.ps1 -Format ALL
    Generate all available report formats (JSON, HTML, CSV)

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
    [ValidateSet("JSON", "HTML", "CSV", "ALL")]
    [string[]]$Format,

    [Parameter(Mandatory = $false)]
    [string]$RuleFilter,

    [Parameter(Mandatory = $false)]
    [ValidateSet("ERROR", "WARN", "INFO", "DEBUG")]
    [string]$LogLevel,

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
    Write-Host "`n[ADMIN] Requesting Administrator Privileges..." -ForegroundColor Yellow
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
        if ($Format) { $argList += "-Format", ($Format -join ",") }
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
        $json = Get-Content $Path -Raw | ConvertFrom-Json
        # Convert PSCustomObject to Hashtable for easier access
        $config = @{}
        $json.PSObject.Properties | ForEach-Object {
            $config[$_.Name] = $_.Value
        }
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
    
    # Filter rules if specified
    if ($Filter) {
        $ruleFiles = $ruleFiles | Where-Object { 
            $_.BaseName -like "*$Filter*" 
        }
        Write-STIGLog "Filtered to $($ruleFiles.Count) rules matching '$Filter'" -Level INFO
    }
    
    return $ruleFiles
}

function Invoke-STIGRule {
    param(
        [System.IO.FileInfo]$RuleFile,
        [int]$TimeoutSeconds = 30
    )
    
    $ruleResult = @{
        RuleID = $RuleFile.BaseName
        RuleFile = $RuleFile.FullName
        Status = "Error"
        Evidence = ""
        FixText = ""
        ExecutionTime = 0
        ErrorMessage = ""
    }
    
    try {
        Write-STIGLog "Executing rule: $($RuleFile.BaseName)" -Level DEBUG
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Import the rule script
        . $RuleFile.FullName
        
        # Extract function name (should be Test-* based on our naming convention)
        $content = Get-Content $RuleFile.FullName -Raw
        $functionMatch = [regex]::Match($content, 'function\s+(Test-[^\s\{]+)')
        
        if ($functionMatch.Success) {
            $functionName = $functionMatch.Groups[1].Value
            Write-STIGLog "Found function: $functionName" -Level DEBUG
            
            # Execute the rule function directly (simpler than jobs for now)
            try {
                $result = & $functionName
            }
            catch {
                throw "Error executing function: $($_.Exception.Message)"
            }
            
            $stopwatch.Stop()
            $ruleResult.ExecutionTime = $stopwatch.ElapsedMilliseconds
            
            if ($result) {
                # Validate result structure
                if ($result.RuleID -and $result.Status) {
                    $ruleResult.RuleID = $result.RuleID
                    $ruleResult.Status = $result.Status
                    $ruleResult.Evidence = $result.Evidence -join "; "
                    $ruleResult.FixText = $result.FixText
                    Write-STIGLog "Rule completed: $($result.RuleID) - $($result.Status)" -Level INFO
                } else {
                    throw "Invalid rule result structure from $functionName"
                }
            } else {
                throw "No result returned from $functionName"
            }
        } else {
            throw "No Test-* function found in rule file"
        }
    }
    catch {
        $stopwatch.Stop()
        $ruleResult.ExecutionTime = $stopwatch.ElapsedMilliseconds
        $ruleResult.Status = "Error"
        $ruleResult.ErrorMessage = $_.Exception.Message
        Write-STIGLog "Rule failed: $($RuleFile.BaseName) - $($_.Exception.Message)" -Level ERROR
    }
    
    return $ruleResult
}

function Start-STIGAssessment {
    param(
        [array]$Rules,
        [hashtable]$Config
    )
    
    # Start timing
    $startTime = Get-Date
    
    Write-STIGLog "Starting STIG assessment with $($Rules.Count) rules" -Level INFO
    $results = @()
    $compliantCount = 0
    $nonCompliantCount = 0
    $errorCount = 0
    
    # Create progress tracking
    $totalRules = $Rules.Count
    $currentRule = 0
    
    foreach ($rule in $Rules) {
        $currentRule++
        $progressPercent = [math]::Round(($currentRule / $totalRules) * 100, 1)
        
        Write-Progress -Activity "STIG Assessment in Progress" `
                      -Status "Processing rule $currentRule of $totalRules ($progressPercent%)" `
                      -CurrentOperation $rule.BaseName `
                      -PercentComplete $progressPercent
        
        $result = Invoke-STIGRule -RuleFile $rule -TimeoutSeconds $Config.scanning.rule_timeout
        $results += $result
        
        # Update counters
        switch ($result.Status) {
            "Compliant" { $compliantCount++ }
            "Non-Compliant" { $nonCompliantCount++ }
            "Error" { $errorCount++ }
        }
    }
    
    Write-Progress -Activity "STIG Assessment" -Completed
    
    # Calculate duration
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    # Create assessment summary
    $summary = @{
        Assessment = @{
            Name = $Config.assessment.name
            Version = $Config.assessment.version
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Computer = $env:COMPUTERNAME
            User = $env:USERNAME
            Administrator = Test-AdminPrivileges
            Duration = $duration
        }
        Statistics = @{
            TotalRules = $totalRules
            Compliant = $compliantCount
            NonCompliant = $nonCompliantCount
            Errors = $errorCount
            CompliancePercentage = if ($totalRules -gt 0) { 
                [math]::Round((($compliantCount / $totalRules) * 100), 2) 
            } else { 0 }
        }
        Results = $results
    }
    
    Write-STIGLog "Assessment completed: $compliantCount compliant, $nonCompliantCount non-compliant, $errorCount errors" -Level INFO
    return $summary
}

function Export-STIGReport {
    param(
        [hashtable]$AssessmentData,
        [string]$OutputPath,
        [string]$Format = "JSON"
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $baseFileName = "STIG-Assessment-$timestamp"
    
    switch ($Format.ToUpper()) {
        "JSON" {
            $reportPath = Join-Path $OutputPath "$baseFileName.json"
            $AssessmentData | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
            Write-STIGLog "JSON report exported: $reportPath" -Level INFO
        }
        
        "CSV" {
            $reportPath = Join-Path $OutputPath "$baseFileName.csv"
            $csvData = $AssessmentData.Results | Select-Object RuleID, Status, Evidence, FixText, ExecutionTime, ErrorMessage
            $csvData | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
            Write-STIGLog "CSV report exported: $reportPath" -Level INFO
        }
        
        "HTML" {
            $reportPath = Join-Path $OutputPath "$baseFileName.html"
            $htmlContent = Generate-HTMLReport -Data $AssessmentData
            $htmlContent | Out-File -FilePath $reportPath -Encoding UTF8
            Write-STIGLog "HTML report exported: $reportPath" -Level INFO
        }
        
        default {
            throw "Unsupported report format: $Format"
        }
    }
    
    return $reportPath
}

function Generate-HTMLReport {
    param([hashtable]$Data)
    
    $compliantRules = $Data.Results | Where-Object { $_.Status -eq "Compliant" }
    $nonCompliantRules = $Data.Results | Where-Object { $_.Status -eq "Non-Compliant" }
    $errorRules = $Data.Results | Where-Object { $_.Status -eq "Error" }
    
    # Calculate risk score based on non-compliance
    $riskScore = [math]::Round(($nonCompliantRules.Count / $Data.Statistics.TotalRules) * 100, 1)
    $riskLevel = switch ($riskScore) {
        { $_ -le 10 } { @{text="LOW"; color="#27ae60"; bg="#d5f4e6"} }
        { $_ -le 25 } { @{text="MODERATE"; color="#f39c12"; bg="#fef9e7"} }
        { $_ -le 50 } { @{text="HIGH"; color="#e67e22"; bg="#fdf2e9"} }
        default { @{text="CRITICAL"; color="#e74c3c"; bg="#fadbd8"} }
    }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Windows 11 STIG Assessment - Executive Dashboard</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        
        /* Header Section */
        .header {
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            color: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            margin-bottom: 30px;
            position: relative;
            overflow: hidden;
        }
        .header::before {
            content: '';
            position: absolute;
            top: 0;
            right: 0;
            width: 100px;
            height: 100px;
            background: rgba(255,255,255,0.1);
            border-radius: 50%;
            transform: translate(30px, -30px);
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        .header-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 20px;
        }
        .header-info {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        .info-item {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.1em;
        }
        
        /* Executive Summary */
        .executive-summary {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .summary-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }
        .risk-badge {
            background: $($riskLevel.bg);
            color: $($riskLevel.color);
            padding: 10px 20px;
            border-radius: 25px;
            font-weight: bold;
            font-size: 1.1em;
            border: 2px solid $($riskLevel.color);
        }
        
        /* Statistics Dashboard */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 25px 0;
        }
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            text-align: center;
            position: relative;
            overflow: hidden;
            transition: transform 0.3s ease;
        }
        .stat-card:hover { transform: translateY(-5px); }
        .stat-icon {
            font-size: 3em;
            margin-bottom: 15px;
        }
        .stat-number {
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .stat-label {
            font-size: 1.1em;
            color: #7f8c8d;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .compliant { color: #27ae60; }
        .non-compliant { color: #e74c3c; }
        .error { color: #f39c12; }
        .compliance-rate { color: #3498db; }
        
        /* Compliance Progress Bar */
        .progress-container {
            background: #ecf0f1;
            border-radius: 25px;
            padding: 8px;
            margin: 20px 0;
        }
        .progress-bar {
            background: linear-gradient(90deg, #27ae60, #2ecc71);
            height: 30px;
            border-radius: 20px;
            width: $($Data.Statistics.CompliancePercentage)%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            transition: width 0.5s ease;
        }
        
        /* Rule Sections */
        .rules-section {
            background: white;
            margin: 25px 0;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .section-header {
            padding: 20px 30px;
            font-size: 1.5em;
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        .header-compliant { background: linear-gradient(135deg, #27ae60, #2ecc71); color: white; }
        .header-non-compliant { background: linear-gradient(135deg, #e74c3c, #c0392b); color: white; }
        .header-error { background: linear-gradient(135deg, #f39c12, #e67e22); color: white; }
        
        .rules-container { padding: 20px; }
        .rule-item {
            border-left: 5px solid #bdc3c7;
            padding: 20px;
            margin: 15px 0;
            background: linear-gradient(135deg, #f8f9fa, #e9ecef);
            border-radius: 0 10px 10px 0;
            transition: all 0.3s ease;
            position: relative;
        }
        .rule-item:hover {
            transform: translateX(5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .rule-compliant { border-left-color: #27ae60; background: linear-gradient(135deg, #d5f4e6, #a9dfbf); }
        .rule-non-compliant { border-left-color: #e74c3c; background: linear-gradient(135deg, #fadbd8, #f1948a); }
        .rule-error { border-left-color: #f39c12; background: linear-gradient(135deg, #fef9e7, #f7dc6f); }
        
        .rule-header {
            display: flex;
            justify-content: between;
            align-items: center;
            margin-bottom: 15px;
        }
        .rule-id {
            font-weight: bold;
            font-size: 1.2em;
            color: #2c3e50;
        }
        .rule-status {
            font-weight: bold;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 0.9em;
            text-transform: uppercase;
        }
        .status-compliant { background: #27ae60; color: white; }
        .status-non-compliant { background: #e74c3c; color: white; }
        .status-error { background: #f39c12; color: white; }
        
        .evidence {
            font-family: 'Courier New', monospace;
            background: rgba(52, 73, 94, 0.1);
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
            border-left: 3px solid #3498db;
            overflow-x: auto;
        }
        .fix-text {
            background: linear-gradient(135deg, #d5f4e6, #a9dfbf);
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
            border-left: 3px solid #27ae60;
        }
        
        /* Responsive Design */
        @media (max-width: 768px) {
            .header-grid { grid-template-columns: 1fr; }
            .stats-grid { grid-template-columns: 1fr; }
            .header h1 { font-size: 2em; }
            .rule-item { padding: 15px; }
        }
        
        /* Print Styles */
        @media print {
            body { background: white; }
            .container { max-width: none; }
            .stat-card, .rules-section { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>
                <i class="fas fa-shield-alt"></i>
                Windows 11 STIG Assessment Report
            </h1>
            <div class="header-grid">
                <div class="header-info">
                    <div class="info-item">
                        <i class="fas fa-desktop"></i>
                        <span><strong>Assessment:</strong> $($Data.Assessment.Name) v$($Data.Assessment.Version)</span>
                    </div>
                    <div class="info-item">
                        <i class="fas fa-computer"></i>
                        <span><strong>Computer:</strong> $($Data.Assessment.Computer)</span>
                    </div>
                    <div class="info-item">
                        <i class="fas fa-user"></i>
                        <span><strong>User:</strong> $($Data.Assessment.User)</span>
                    </div>
                </div>
                <div class="header-info">
                    <div class="info-item">
                        <i class="fas fa-user-shield"></i>
                        <span><strong>Admin:</strong> $($Data.Assessment.Administrator)</span>
                    </div>
                    <div class="info-item">
                        <i class="fas fa-calendar"></i>
                        <span><strong>Generated:</strong> $($Data.Assessment.Timestamp)</span>
                    </div>
                    <div class="info-item">
                        <i class="fas fa-clock"></i>
                        <span><strong>Duration:</strong> $([math]::Round($Data.Assessment.Duration, 2)) seconds</span>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="executive-summary">
            <div class="summary-header">
                <h2><i class="fas fa-chart-line"></i> Executive Summary</h2>
                <div class="risk-badge">
                    <i class="fas fa-exclamation-triangle"></i>
                    RISK LEVEL: $($riskLevel.text)
                </div>
            </div>
            
            <div class="progress-container">
                <div class="progress-bar">
                    $($Data.Statistics.CompliancePercentage)% Compliant
                </div>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon compliant">
                        <i class="fas fa-check-circle"></i>
                    </div>
                    <div class="stat-number compliant">$($Data.Statistics.Compliant)</div>
                    <div class="stat-label">Compliant Rules</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon non-compliant">
                        <i class="fas fa-times-circle"></i>
                    </div>
                    <div class="stat-number non-compliant">$($Data.Statistics.NonCompliant)</div>
                    <div class="stat-label">Non-Compliant Rules</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon error">
                        <i class="fas fa-exclamation-circle"></i>
                    </div>
                    <div class="stat-number error">$($Data.Statistics.Errors)</div>
                    <div class="stat-label">Error Rules</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon compliance-rate">
                        <i class="fas fa-percentage"></i>
                    </div>
                    <div class="stat-number compliance-rate">$($Data.Statistics.CompliancePercentage)%</div>
                    <div class="stat-label">Compliance Rate</div>
                </div>
            </div>
        </div>
"@

    if ($nonCompliantRules.Count -gt 0) {
        $html += @"
        <div class="rules-section">
            <div class="section-header header-non-compliant">
                <i class="fas fa-times-circle"></i>
                Non-Compliant Rules ($($nonCompliantRules.Count))
            </div>
            <div class="rules-container">
"@
        foreach ($rule in $nonCompliantRules) {
            $html += @"
                <div class="rule-item rule-non-compliant">
                    <div class="rule-header">
                        <div class="rule-id">$($rule.RuleID)</div>
                        <div class="rule-status status-non-compliant">Non-Compliant</div>
                    </div>
                    <div class="evidence"><strong><i class="fas fa-search"></i> Evidence:</strong><br>$($rule.Evidence)</div>
                    <div class="fix-text"><strong><i class="fas fa-tools"></i> Remediation:</strong><br>$($rule.FixText)</div>
                </div>
"@
        }
        $html += @"
            </div>
        </div>
"@
    }

    if ($errorRules.Count -gt 0) {
        $html += @"
        <div class="rules-section">
            <div class="section-header header-error">
                <i class="fas fa-exclamation-circle"></i>
                Rules with Errors ($($errorRules.Count))
            </div>
            <div class="rules-container">
"@
        foreach ($rule in $errorRules) {
            $html += @"
                <div class="rule-item rule-error">
                    <div class="rule-header">
                        <div class="rule-id">$($rule.RuleID)</div>
                        <div class="rule-status status-error">Error</div>
                    </div>
                    <div class="evidence"><strong><i class="fas fa-bug"></i> Error Details:</strong><br>$($rule.ErrorMessage)</div>
                </div>
"@
        }
        $html += @"
            </div>
        </div>
"@
    }

    if ($compliantRules.Count -gt 0) {
        $html += @"
        <div class="rules-section">
            <div class="section-header header-compliant">
                <i class="fas fa-check-circle"></i>
                Compliant Rules ($($compliantRules.Count))
            </div>
            <div class="rules-container">
"@
        foreach ($rule in $compliantRules) {
            $html += @"
                <div class="rule-item rule-compliant">
                    <div class="rule-header">
                        <div class="rule-id">$($rule.RuleID)</div>
                        <div class="rule-status status-compliant">Compliant</div>
                    </div>
                    <div class="evidence"><strong><i class="fas fa-check"></i> Evidence:</strong><br>$($rule.Evidence)</div>
                </div>
"@
        }
        $html += @"
            </div>
        </div>
"@
    }

    $html += @"
    </div>
    
    <script>
        // Add interactive features
        document.addEventListener('DOMContentLoaded', function() {
            // Animate progress bar
            const progressBar = document.querySelector('.progress-bar');
            if (progressBar) {
                progressBar.style.width = '0%';
                setTimeout(() => {
                    progressBar.style.width = '$($Data.Statistics.CompliancePercentage)%';
                }, 500);
            }
            
            // Add click handlers for rule items
            document.querySelectorAll('.rule-item').forEach(item => {
                item.addEventListener('click', function() {
                    this.style.transform = this.style.transform === 'translateX(10px)' ? 'translateX(5px)' : 'translateX(10px)';
                });
            });
        });
    </script>
</body>
</html>
"@

    return $html
}

function Show-AssessmentSummary {
    param(
        [hashtable]$Config,
        [array]$Rules,
        [string]$OutputPath
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "Windows 11 STIG Assessment Tool" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "LIVE COMPLIANCE ASSESSMENT" -ForegroundColor Yellow
    Write-Host "Testing Real Windows Security Settings (Not Development Tests)" -ForegroundColor Gray
    Write-Host ""
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

function Show-AssessmentResults {
    param([hashtable]$Results)
    
    Write-Host "`nAssessment Results" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Cyan
    Write-Host "Total Rules:    " -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.TotalRules -ForegroundColor Green
    Write-Host "Compliant:      " -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.Compliant -ForegroundColor Green
    Write-Host "Non-Compliant:  " -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.NonCompliant -ForegroundColor Red
    Write-Host "Errors:         " -NoNewline -ForegroundColor White
    Write-Host $Results.Statistics.Errors -ForegroundColor Yellow
    Write-Host "Compliance:     " -NoNewline -ForegroundColor White
    Write-Host "$($Results.Statistics.CompliancePercentage)%" -ForegroundColor $(
        if ($Results.Statistics.CompliancePercentage -ge 90) { "Green" }
        elseif ($Results.Statistics.CompliancePercentage -ge 75) { "Yellow" }
        else { "Red" }
    )
    Write-Host "=" * 30 -ForegroundColor Cyan
}

#endregion

#region Main Execution

try {
    # Load configuration
    $script:Config = Import-Configuration -Path $ConfigPath
    
    # Override config with parameters
    if ($LogLevel) { $script:Config.logging.level = $LogLevel }
    if ($Format) { 
        # Handle multiple formats and "ALL" option
        if ($Format -contains "ALL") {
            $script:Config.reporting.export_formats = @("JSON", "HTML", "CSV")
        } else {
            $script:Config.reporting.export_formats = $Format
        }
    }
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
    $coreRules = Get-STIGRules -RulesPath $script:Config.rules.core_rules_path -Filter $RuleFilter
    $customRules = @()
    
    if ($script:Config.scanning.include_custom_rules) {
        $customRules = Get-STIGRules -RulesPath $script:Config.rules.custom_rules_path -Filter $RuleFilter
    }
    
    # Combine rules arrays properly
    $allRules = @()
    $allRules += $coreRules
    $allRules += $customRules
    
    if ($allRules.Count -eq 0) {
        throw "No STIG rules found. Check rules directories."
    }
    
    # Show assessment summary
    Show-AssessmentSummary -Config $script:Config -Rules $allRules -OutputPath $OutputPath
    
    if ($WhatIf) {
        Write-STIGLog "WhatIf mode - Assessment preview completed" -Level INFO
        Write-Host "Assessment would process $($allRules.Count) rules" -ForegroundColor Yellow
        foreach ($rule in $allRules) {
            Write-Host "  - $($rule.BaseName)" -ForegroundColor Gray
        }
        return
    }
    
    # Execute STIG assessment
    Write-STIGLog "Starting STIG rule execution..." -Level INFO
    $assessmentResults = Start-STIGAssessment -Rules $allRules -Config $script:Config
    
    # Show results summary
    Show-AssessmentResults -Results $assessmentResults
    
    # Export reports
    $reportFormats = if ($Format) { 
        if ($Format -contains "ALL") { 
            @("JSON", "HTML", "CSV") 
        } else { 
            $Format 
        }
    } else { 
        $script:Config.reporting.export_formats 
    }
    
    Write-Host "`n[REPORTS] Generating Reports..." -ForegroundColor Cyan
    
    foreach ($reportFormat in $reportFormats) {
        try {
            Write-Host "  Creating $reportFormat report..." -ForegroundColor Yellow
            $reportPath = Export-STIGReport -AssessmentData $assessmentResults -OutputPath $OutputPath -Format $reportFormat
            Write-Host "  [SUCCESS] $reportFormat report: " -NoNewline -ForegroundColor Green
            Write-Host $reportPath -ForegroundColor White
        }
        catch {
            Write-STIGLog "Failed to generate $reportFormat report: $($_.Exception.Message)" -Level ERROR
            Write-Host "  [ERROR] Failed to generate $reportFormat report" -ForegroundColor Red
        }
    }
    
    Write-STIGLog "Assessment completed successfully" -Level INFO
    
} catch {
    Write-STIGLog "Assessment failed: $($_.Exception.Message)" -Level ERROR -ToHost
    exit 1
}

#endregion

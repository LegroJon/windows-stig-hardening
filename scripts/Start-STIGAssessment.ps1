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
    
    # Create assessment summary
    $summary = @{
        Assessment = @{
            Name = $Config.assessment.name
            Version = $Config.assessment.version
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Computer = $env:COMPUTERNAME
            User = $env:USERNAME
            Administrator = Test-AdminPrivileges
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
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 STIG Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .summary { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .statistics { display: flex; justify-content: space-around; margin: 20px 0; }
        .stat-box { text-align: center; padding: 15px; background-color: #ecf0f1; border-radius: 5px; margin: 0 10px; }
        .stat-number { font-size: 2em; font-weight: bold; }
        .compliant { color: #27ae60; }
        .non-compliant { color: #e74c3c; }
        .error { color: #f39c12; }
        .rules-section { background-color: white; margin: 20px 0; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .rule-item { border-left: 4px solid #bdc3c7; padding: 10px; margin: 10px 0; background-color: #f8f9fa; }
        .rule-compliant { border-left-color: #27ae60; }
        .rule-non-compliant { border-left-color: #e74c3c; }
        .rule-error { border-left-color: #f39c12; }
        .rule-id { font-weight: bold; color: #2c3e50; }
        .rule-status { font-weight: bold; }
        .evidence { font-family: monospace; background-color: #f1f2f6; padding: 5px; border-radius: 3px; margin: 5px 0; }
        .fix-text { background-color: #dff0d8; padding: 10px; border-radius: 3px; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ Windows 11 STIG Assessment Report</h1>
        <p><strong>Assessment:</strong> $($Data.Assessment.Name) v$($Data.Assessment.Version)</p>
        <p><strong>Computer:</strong> $($Data.Assessment.Computer) | <strong>User:</strong> $($Data.Assessment.User) | <strong>Admin:</strong> $($Data.Assessment.Administrator)</p>
        <p><strong>Generated:</strong> $($Data.Assessment.Timestamp)</p>
    </div>
    
    <div class="summary">
        <h2>📊 Assessment Summary</h2>
        <div class="statistics">
            <div class="stat-box">
                <div class="stat-number compliant">$($Data.Statistics.Compliant)</div>
                <div>Compliant</div>
            </div>
            <div class="stat-box">
                <div class="stat-number non-compliant">$($Data.Statistics.NonCompliant)</div>
                <div>Non-Compliant</div>
            </div>
            <div class="stat-box">
                <div class="stat-number error">$($Data.Statistics.Errors)</div>
                <div>Errors</div>
            </div>
            <div class="stat-box">
                <div class="stat-number">$($Data.Statistics.CompliancePercentage)%</div>
                <div>Compliance Rate</div>
            </div>
        </div>
    </div>
"@

    if ($nonCompliantRules.Count -gt 0) {
        $html += @"
    <div class="rules-section">
        <h2 class="non-compliant">❌ Non-Compliant Rules ($($nonCompliantRules.Count))</h2>
"@
        foreach ($rule in $nonCompliantRules) {
            $html += @"
        <div class="rule-item rule-non-compliant">
            <div class="rule-id">$($rule.RuleID)</div>
            <div class="rule-status non-compliant">Status: $($rule.Status)</div>
            <div class="evidence"><strong>Evidence:</strong> $($rule.Evidence)</div>
            <div class="fix-text"><strong>Remediation:</strong> $($rule.FixText)</div>
        </div>
"@
        }
        $html += "    </div>"
    }

    if ($errorRules.Count -gt 0) {
        $html += @"
    <div class="rules-section">
        <h2 class="error">⚠️ Rules with Errors ($($errorRules.Count))</h2>
"@
        foreach ($rule in $errorRules) {
            $html += @"
        <div class="rule-item rule-error">
            <div class="rule-id">$($rule.RuleID)</div>
            <div class="rule-status error">Status: $($rule.Status)</div>
            <div class="evidence"><strong>Error:</strong> $($rule.ErrorMessage)</div>
        </div>
"@
        }
        $html += "    </div>"
    }

    if ($compliantRules.Count -gt 0) {
        $html += @"
    <div class="rules-section">
        <h2 class="compliant">✅ Compliant Rules ($($compliantRules.Count))</h2>
"@
        foreach ($rule in $compliantRules) {
            $html += @"
        <div class="rule-item rule-compliant">
            <div class="rule-id">$($rule.RuleID)</div>
            <div class="rule-status compliant">Status: $($rule.Status)</div>
            <div class="evidence"><strong>Evidence:</strong> $($rule.Evidence)</div>
        </div>
"@
        }
        $html += "    </div>"
    }

    $html += @"
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
    $reportFormats = if ($Format) { @($Format) } else { $script:Config.reporting.export_formats }
    
    foreach ($reportFormat in $reportFormats) {
        try {
            $reportPath = Export-STIGReport -AssessmentData $assessmentResults -OutputPath $OutputPath -Format $reportFormat
            Write-Host "📄 Report generated: " -NoNewline -ForegroundColor White
            Write-Host $reportPath -ForegroundColor Green
        }
        catch {
            Write-STIGLog "Failed to generate $reportFormat report: $($_.Exception.Message)" -Level ERROR
        }
    }
    
    Write-STIGLog "Assessment completed successfully" -Level INFO
    
} catch {
    Write-STIGLog "Assessment failed: $($_.Exception.Message)" -Level ERROR -ToHost
    exit 1
}

#endregion

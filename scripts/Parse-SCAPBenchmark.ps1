<#
.SYNOPSIS
    SCAP Benchmark Parser - Extracts STIG rules from DISA SCAP XML files

.DESCRIPTION
    This script parses the Windows 11 STIG SCAP Benchmark XML file and extracts
    rule information to generate PowerShell STIG compliance check scripts.

.PARAMETER SCAPFilePath
    Path to the SCAP Benchmark XML file

.PARAMETER OutputDirectory
    Directory to create the rule scripts (default: .\rules\core)

.PARAMETER MaxRules
    Maximum number of rules to process (for testing, default: all)

.EXAMPLE
    .\Parse-SCAPBenchmark.ps1 -SCAPFilePath "C:\Downloads\U_MS_Windows_11_V2R4_STIG_SCAP_1-3_Benchmark.xml"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$SCAPFilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = ".\rules\core",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxRules = 0
)

function ConvertTo-PowerShellFunctionName {
    param([string]$RuleID)
    
    # Convert rule ID to valid PowerShell function name
    $cleanID = $RuleID -replace '[^a-zA-Z0-9]', ''
    return "Test-$cleanID"
}

function Extract-RuleFromXCCDF {
    param([System.Xml.XmlElement]$RuleElement)
    
    try {
        $ruleID = $ruleElement.id
        $title = $ruleElement.title.'#text'
        $description = $ruleElement.description.'#text'
        
        # Extract severity from rule attributes
        $severity = switch ($ruleElement.severity) {
            "high" { "CAT I" }
            "medium" { "CAT II" }
            "low" { "CAT III" }
            default { "CAT II" }
        }
        
        # Extract check content
        $checkContent = ""
        $fixText = ""
        
        if ($ruleElement.check -and $ruleElement.check.'check-content') {
            $checkContent = $ruleElement.check.'check-content'.'#text'
        }
        
        if ($ruleElement.fixtext) {
            $fixText = $ruleElement.fixtext.'#text'
        }
        
        return @{
            RuleID = $ruleID
            Title = $title
            Description = $description
            Severity = $severity
            CheckContent = $checkContent
            FixText = $fixText
        }
    }
    catch {
        Write-Warning "Failed to parse rule: $($_.Exception.Message)"
        return $null
    }
}

function Generate-STIGRuleScript {
    param(
        [hashtable]$RuleData,
        [string]$OutputDir
    )
    
    $functionName = ConvertTo-PowerShellFunctionName -RuleID $RuleData.RuleID
    $ruleFileName = "$($RuleData.RuleID).ps1"
    $ruleFilePath = Join-Path $OutputDir $ruleFileName
    
    # Analyze check content to determine implementation approach
    $implementationHint = ""
    $sampleCode = ""
    
    if ($RuleData.CheckContent -match "registry|Get-ItemProperty|HKLM:|HKCU:") {
        $implementationHint = "# Registry-based check detected"
        $sampleCode = @"
        # Example registry check (modify as needed):
        `$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
        `$registryValue = "ValueName"
        
        if (Test-Path `$registryPath) {
            `$currentValue = Get-ItemProperty -Path `$registryPath -Name `$registryValue -ErrorAction SilentlyContinue
            if (`$currentValue.`$registryValue -eq "ExpectedValue") {
                `$status = "Compliant"
                `$evidence = "Registry value is correctly configured"
            } else {
                `$status = "Non-Compliant"
                `$evidence = "Registry value is not configured correctly"
            }
        } else {
            `$status = "Non-Compliant"
            `$evidence = "Registry path does not exist"
        }
"@
    }
    elseif ($RuleData.CheckContent -match "service|Get-Service") {
        $implementationHint = "# Service-based check detected"
        $sampleCode = @"
        # Example service check (modify as needed):
        `$serviceName = "ServiceName"
        `$service = Get-Service -Name `$serviceName -ErrorAction SilentlyContinue
        
        if (`$service) {
            if (`$service.Status -eq "Stopped" -and `$service.StartType -eq "Disabled") {
                `$status = "Compliant"
                `$evidence = "Service `$serviceName is properly disabled"
            } else {
                `$status = "Non-Compliant"
                `$evidence = "Service `$serviceName is not properly configured (Status: `$(`$service.Status), StartType: `$(`$service.StartType))"
            }
        } else {
            `$status = "Non-Compliant"
            `$evidence = "Service `$serviceName not found"
        }
"@
    }
    elseif ($RuleData.CheckContent -match "auditpol|audit") {
        $implementationHint = "# Audit policy check detected"
        $sampleCode = @"
        # Example audit policy check (modify as needed):
        `$auditCategory = "Category Name"
        `$auditResult = auditpol /get /category:"`$auditCategory" 2>$null
        
        if (`$auditResult -match "Success and Failure") {
            `$status = "Compliant"
            `$evidence = "Audit policy correctly configured for `$auditCategory"
        } else {
            `$status = "Non-Compliant"
            `$evidence = "Audit policy not correctly configured for `$auditCategory"
        }
"@
    }
    else {
        $implementationHint = "# Generic check - needs manual implementation"
        $sampleCode = @"
        # TODO: Implement specific check based on STIG requirements
        `$status = "Error"
        `$evidence = "Check not yet implemented"
"@
    }
    
    $ruleTemplate = @"
<#
.SYNOPSIS
    $($RuleData.Title)

.DESCRIPTION
    STIG Rule: $($RuleData.RuleID)
    Category: $($RuleData.Severity)
    
    $($RuleData.Description)

.NOTES
    Generated from DISA STIG SCAP Benchmark
    Rule ID: $($RuleData.RuleID)
    Severity: $($RuleData.Severity)
    
    Check Content:
    $($RuleData.CheckContent)
#>

function $functionName {
    try {
        $implementationHint
        
$sampleCode
        
        return @{
            RuleID   = "$($RuleData.RuleID)"
            Status   = `$status
            Evidence = `$evidence
            FixText  = "$($RuleData.FixText)"
        }
    }
    catch {
        return @{
            RuleID   = "$($RuleData.RuleID)"
            Status   = "Error"
            Evidence = "Error checking compliance: `$(`$_.Exception.Message)"
            FixText  = "$($RuleData.FixText)"
        }
    }
}
"@

    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Write the rule script
    $ruleTemplate | Out-File -FilePath $ruleFilePath -Encoding UTF8
    
    return $ruleFilePath
}

# Main execution
Write-Host "`nSCAP Benchmark Parser - Windows 11 STIG" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

try {
    # Load the SCAP XML file
    Write-Host "Loading SCAP file: $SCAPFilePath" -ForegroundColor White
    [xml]$scapXml = Get-Content $SCAPFilePath
    
    # Find XCCDF benchmark rules
    $rules = $scapXml.SelectNodes("//xccdf:Rule", @{xccdf="http://checklists.nist.gov/xccdf/1.2"})
    
    if (-not $rules -or $rules.Count -eq 0) {
        # Try without namespace
        $rules = $scapXml.SelectNodes("//Rule")
    }
    
    Write-Host "Found $($rules.Count) STIG rules in SCAP file" -ForegroundColor Green
    
    if ($MaxRules -gt 0 -and $rules.Count -gt $MaxRules) {
        $rules = $rules[0..($MaxRules-1)]
        Write-Host "Limited to first $MaxRules rules for processing" -ForegroundColor Yellow
    }
    
    $processedCount = 0
    $errorCount = 0
    
    foreach ($rule in $rules) {
        try {
            $ruleData = Extract-RuleFromXCCDF -RuleElement $rule
            
            if ($ruleData) {
                $ruleFile = Generate-STIGRuleScript -RuleData $ruleData -OutputDir $OutputDirectory
                Write-Host "[SUCCESS] Created: $($ruleData.RuleID) - $($ruleData.Title)" -ForegroundColor Green
                $processedCount++
            }
        }
        catch {
            Write-Warning "Failed to process rule: $($_.Exception.Message)"
            $errorCount++
        }
    }
    
    # Summary
    Write-Host "`n[REPORT] Processing Summary" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Cyan
    Write-Host "Total Rules Found: $($rules.Count)" -ForegroundColor White
    Write-Host "Successfully Processed: $processedCount" -ForegroundColor Green
    Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host "Output Directory: $OutputDirectory" -ForegroundColor White
    
    Write-Host "`n[NEXT] Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Review generated rule scripts in $OutputDirectory" -ForegroundColor Gray
    Write-Host "2. Implement specific check logic based on STIG requirements" -ForegroundColor Gray
    Write-Host "3. Test rules: .\scripts\Start-STIGAssessment.ps1" -ForegroundColor Gray
    Write-Host "4. Update rules.json metadata" -ForegroundColor Gray
    
}
catch {
    Write-Error "Failed to process SCAP file: $($_.Exception.Message)"
    exit 1
}

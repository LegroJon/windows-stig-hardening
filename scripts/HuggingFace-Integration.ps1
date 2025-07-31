# Hugging Face Integration Module
# Windows 11 STIG Assessment Tool - AI Enhancement

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Model = "microsoft/DialoGPT-medium",
    
    [Parameter(Mandatory = $false)]
    [switch]$TestConnection,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnhanceReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportFile = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeEvidence
)

# Configuration
$script:HuggingFaceConfig = @{
    BaseUrl = "https://api-inference.huggingface.co"
    ModelsUrl = "https://huggingface.co/api/models"
    DefaultModel = "microsoft/DialoGPT-medium"
    CybersecurityModels = @(
        "danitamayo/bert-cybersecurity-NER",
        "bnsapa/cybersecurity-ner",
        "sudipadhikari/cybersecurity_ner"
    )
    ComplianceModels = @(
        "Vineetttt/compliance_monitoring_oms",
        "comethrusws/finlytic-compliance"
    )
}

function Test-HuggingFaceConnection {
    Write-Host "[INFO] Testing Hugging Face connectivity..." -ForegroundColor Yellow
    
    try {
        # Test basic API connectivity
        $response = Invoke-WebRequest -Uri $script:HuggingFaceConfig.ModelsUrl -Method HEAD -UseBasicParsing -TimeoutSec 10
        
        if ($response.StatusCode -eq 200) {
            Write-Host "[SUCCESS] Hugging Face Hub is accessible" -ForegroundColor Green
            
            # Test inference API (without API key will return 401, which is expected)
            try {
                $inferenceTest = Invoke-WebRequest -Uri "$($script:HuggingFaceConfig.BaseUrl)/models/bert-base-uncased" -Method HEAD -UseBasicParsing -TimeoutSec 5
            } catch {
                if ($_.Exception.Response.StatusCode -eq 401) {
                    Write-Host "[INFO] Inference API accessible (API key required for usage)" -ForegroundColor Cyan
                } else {
                    Write-Host "[WARNING] Inference API test failed: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            return $true
        } else {
            Write-Host "[ERROR] Unexpected response from Hugging Face: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to connect to Hugging Face: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-CybersecurityModels {
    Write-Host "[INFO] Retrieving cybersecurity models..." -ForegroundColor Yellow
    
    try {
        $models = Invoke-RestMethod -Uri "$($script:HuggingFaceConfig.ModelsUrl)?search=cybersecurity&limit=20" -Method GET
        
        Write-Host "[SUCCESS] Found $($models.Count) cybersecurity models" -ForegroundColor Green
        
        foreach ($model in $models) {
            Write-Host "  - $($model.id) ($($model.downloads) downloads)" -ForegroundColor Cyan
        }
        
        return $models
    } catch {
        Write-Host "[ERROR] Failed to retrieve models: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Invoke-HuggingFaceInference {
    param(
        [string]$ModelName,
        [string]$Text,
        [string]$Task = "text-generation"
    )
    
    if (-not $ApiKey) {
        Write-Host "[WARNING] No API key provided - using mock response" -ForegroundColor Yellow
        return @{
            mock = $true
            input = $Text
            task = $Task
            model = $ModelName
            result = "Mock AI analysis: This appears to be a cybersecurity compliance assessment finding that requires attention."
        }
    }
    
    try {
        $headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type" = "application/json"
        }
        
        $body = @{
            inputs = $Text
            parameters = @{
                max_length = 100
                temperature = 0.7
            }
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$($script:HuggingFaceConfig.BaseUrl)/models/$ModelName" -Method POST -Headers $headers -Body $body
        
        return $response
    } catch {
        Write-Host "[ERROR] Hugging Face inference failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-ComplianceSummary {
    param([object]$AssessmentResults)
    
    Write-Host "[INFO] Generating AI-enhanced compliance summary..." -ForegroundColor Yellow
    
    # Create summary text from results
    $totalRules = $AssessmentResults.Count
    $compliant = ($AssessmentResults | Where-Object { $_.Status -eq "Compliant" }).Count
    $nonCompliant = $totalRules - $compliant
    $complianceRate = [math]::Round(($compliant / $totalRules) * 100, 1)
    
    $summaryText = @"
System Assessment Summary:
- Total Rules Assessed: $totalRules
- Compliant: $compliant ($complianceRate%)
- Non-Compliant: $nonCompliant
- Top Violations: $(($AssessmentResults | Where-Object { $_.Status -eq "Non-Compliant" } | Select-Object -First 3 -ExpandProperty RuleID) -join ", ")
"@
    
    # Mock AI enhancement (replace with actual Hugging Face call when API key available)
    $aiSummary = @{
        ExecutiveSummary = "The system shows a $complianceRate% compliance rate with Windows 11 STIG requirements. Priority should be given to addressing the $nonCompliant non-compliant findings to improve the security posture."
        RiskAssessment = if ($complianceRate -ge 90) { "LOW" } elseif ($complianceRate -ge 70) { "MEDIUM" } else { "HIGH" }
        NextSteps = @(
            "Address high-priority non-compliant findings",
            "Review system configuration against NIST frameworks",
            "Schedule follow-up assessment after remediation"
        )
        TechnicalDetails = $summaryText
    }
    
    return $aiSummary
}

function Get-IntelligentRemediation {
    param(
        [string]$RuleID,
        [string]$Finding,
        [string]$OriginalFixText
    )
    
    Write-Host "[INFO] Generating intelligent remediation guidance for $RuleID..." -ForegroundColor Yellow
    
    # Mock AI-enhanced remediation (replace with actual model call)
    $enhancedRemediation = @{
        RuleID = $RuleID
        OriginalFixText = $OriginalFixText
        EnhancedGuidance = @{
            Summary = "AI-enhanced remediation guidance for improved clarity and context"
            Steps = @(
                "1. Review current configuration against security requirements",
                "2. Apply recommended changes using provided PowerShell commands",
                "3. Validate changes and test system functionality",
                "4. Document changes for compliance audit trail"
            )
            RiskContext = "This finding represents a moderate security risk that should be addressed promptly"
            RelatedControls = @("NIST-800-53 AC-2", "NIST CSF PR.AC-1")
        }
        Confidence = 0.85
    }
    
    return $enhancedRemediation
}

function Enhance-STIGReport {
    param([string]$ReportPath)
    
    if (-not (Test-Path $ReportPath)) {
        Write-Host "[ERROR] Report file not found: $ReportPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "[INFO] Enhancing STIG report with AI analysis..." -ForegroundColor Yellow
    
    try {
        $reportData = Get-Content $ReportPath | ConvertFrom-Json
        
        # Generate AI-enhanced summary
        $aiSummary = Get-ComplianceSummary -AssessmentResults $reportData.Results
        
        # Add AI enhancements to report
        $reportData | Add-Member -NotePropertyName "AI_Enhancement" -NotePropertyValue @{
            GeneratedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            Provider = "Hugging Face Integration"
            ExecutiveSummary = $aiSummary.ExecutiveSummary
            RiskAssessment = $aiSummary.RiskAssessment
            NextSteps = $aiSummary.NextSteps
            ModelUsed = "Mock AI Analysis (API key required for actual models)"
        }
        
        # Save enhanced report
        $enhancedPath = $ReportPath -replace "\.json$", "-AI-Enhanced.json"
        $reportData | ConvertTo-Json -Depth 10 | Set-Content $enhancedPath
        
        Write-Host "[SUCCESS] AI-enhanced report saved: $enhancedPath" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "[ERROR] Failed to enhance report: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution logic
function Invoke-HuggingFaceIntegration {
    Write-Host "[STIG] Hugging Face AI Integration Module" -ForegroundColor Cyan
    Write-Host "[INFO] AI enhancement for cybersecurity compliance assessment" -ForegroundColor Yellow
    
    if ($TestConnection) {
        $connectionResult = Test-HuggingFaceConnection
        if ($connectionResult) {
            Get-CybersecurityModels | Out-Null
        }
        return
    }
    
    if ($EnhanceReport -and $ReportFile) {
        $result = Enhance-STIGReport -ReportPath $ReportFile
        if ($result) {
            Write-Host "[NEXT] Review the AI-enhanced report for improved insights" -ForegroundColor Cyan
        }
        return
    }
    
    if ($AnalyzeEvidence) {
        Write-Host "[INFO] AI evidence analysis would analyze system output for compliance indicators" -ForegroundColor Yellow
        Write-Host "[INFO] This feature requires API key and specific model configuration" -ForegroundColor Yellow
        return
    }
    
    # Default: Show capabilities
    Write-Host "`n[INFO] Hugging Face Integration Capabilities:" -ForegroundColor Green
    Write-Host "1. Report Enhancement: AI-generated executive summaries" -ForegroundColor Cyan
    Write-Host "2. Evidence Analysis: Intelligent parsing of system output" -ForegroundColor Cyan
    Write-Host "3. Remediation Guidance: Enhanced fix instructions" -ForegroundColor Cyan
    Write-Host "4. Risk Assessment: AI-driven vulnerability prioritization" -ForegroundColor Cyan
    
    Write-Host "`n[USAGE] Example commands:" -ForegroundColor Yellow
    Write-Host "Test connectivity: .\scripts\HuggingFace-Integration.ps1 -TestConnection" -ForegroundColor White
    Write-Host "Enhance report: .\scripts\HuggingFace-Integration.ps1 -EnhanceReport -ReportFile 'report.json'" -ForegroundColor White
    Write-Host "Set API key: .\scripts\HuggingFace-Integration.ps1 -ApiKey 'your-api-key'" -ForegroundColor White
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-HuggingFaceIntegration
}

# MCP Server Test Script
# Demonstrates NIST NCP Repository Integration

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ServerUrl = "http://localhost:8080"
)

Write-Host "[STIG] MCP Server Integration Test" -ForegroundColor Cyan
Write-Host "[INFO] Testing MCP server functionality..." -ForegroundColor Yellow

# Test 1: Health Check
Write-Host "`n[TEST 1] Health Check" -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "$ServerUrl/health" -Method GET
    Write-Host "[SUCCESS] Server Status: $($health.status)" -ForegroundColor Green
    Write-Host "[INFO] Server Version: $($health.version)" -ForegroundColor Yellow
    Write-Host "[INFO] Timestamp: $($health.timestamp)" -ForegroundColor Yellow
} catch {
    Write-Host "[ERROR] Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: NIST Frameworks
Write-Host "`n[TEST 2] NIST Frameworks" -ForegroundColor Cyan
try {
    $frameworks = Invoke-RestMethod -Uri "$ServerUrl/api/nist/frameworks" -Method GET
    if ($frameworks.success) {
        Write-Host "[SUCCESS] Retrieved NIST frameworks" -ForegroundColor Green
        Write-Host "[INFO] Framework count: $($frameworks.data.frameworks.Count)" -ForegroundColor Yellow
        
        foreach ($framework in $frameworks.data.frameworks) {
            Write-Host "  - $($framework.name) ($($framework.version))" -ForegroundColor Cyan
        }
    } else {
        Write-Host "[ERROR] Failed to retrieve frameworks" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Frameworks test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: NIST Controls
Write-Host "`n[TEST 3] NIST Controls" -ForegroundColor Cyan
try {
    $controls = Invoke-RestMethod -Uri "$ServerUrl/api/nist/frameworks/nist-800-53/controls" -Method GET
    if ($controls.success) {
        Write-Host "[SUCCESS] Retrieved NIST 800-53 controls" -ForegroundColor Green
        Write-Host "[INFO] Control count: $($controls.data.controls.Count)" -ForegroundColor Yellow
        
        foreach ($control in $controls.data.controls) {
            Write-Host "  - $($control.id): $($control.name)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "[ERROR] Failed to retrieve controls" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Controls test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Compliance Submission
Write-Host "`n[TEST 4] Compliance Submission" -ForegroundColor Cyan
try {
    $testSubmission = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        report_type = "test-assessment"
        system_info = @{
            hostname = $env:COMPUTERNAME
            domain = $env:USERDNSDOMAIN
            os_version = (Get-CimInstance Win32_OperatingSystem).Version
        }
        nist_mapping = $true
        results = @(
            @{
                RuleID = "WN11-SO-000001"
                Status = "Compliant"
                Evidence = "SMBv1 is disabled"
                FixText = "N/A - Already compliant"
                NISTMappings = @("SC-8", "SC-13")
            }
        )
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$ServerUrl/api/compliance/submit" -Method POST -Body $testSubmission -ContentType "application/json"
    
    if ($response.success) {
        Write-Host "[SUCCESS] Compliance submission accepted" -ForegroundColor Green
        Write-Host "[INFO] Report ID: $($response.report_id)" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Compliance submission failed" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Compliance submission test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Organization Baseline
Write-Host "`n[TEST 5] Organization Baseline" -ForegroundColor Cyan
try {
    $baseline = Invoke-RestMethod -Uri "$ServerUrl/api/organization/baseline/cybersecurity-framework" -Method GET
    if ($baseline.success) {
        Write-Host "[SUCCESS] Retrieved organization baseline" -ForegroundColor Green
        Write-Host "[INFO] Profile: $($baseline.data.profile)" -ForegroundColor Yellow
        Write-Host "[INFO] Control count: $($baseline.data.baseline.controls.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Failed to retrieve baseline" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Baseline test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[COMPLETE] MCP Server integration tests completed" -ForegroundColor Green
Write-Host "[INFO] Server URL: $ServerUrl" -ForegroundColor Yellow
Write-Host "[NEXT] Use '.\scripts\MCP-NISTIntegration.ps1' for production integration" -ForegroundColor Cyan

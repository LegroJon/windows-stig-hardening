# Debug Test Script for STIG Assessment Tool
# This script demonstrates the debugging capabilities

param(
    [switch]$Verbose,
    [string]$TestType = "Basic"
)

Write-Host "[STIG] Starting Debug Test" -ForegroundColor Cyan

# Test 1: Variable inspection
$debugVariables = @{
    ProjectName = "Windows 11 STIG Assessment Tool"
    Version = "1.0.0"
    TestMode = $true
    Timestamp = Get-Date
}

Write-Host "[DEBUG] Debug variables initialized" -ForegroundColor Gray
if ($Verbose) {
    Write-Host "[VERBOSE] Variables: $($debugVariables | ConvertTo-Json -Compress)" -ForegroundColor Yellow
}

# Test 2: Function call debugging
function Test-DebugFunction {
    param([string]$Message)
    
    Write-Host "[DEBUG] Function called with message: $Message" -ForegroundColor Green
    
    # Simulate some processing
    Start-Sleep -Milliseconds 500
    
    return @{
        Status = "Success"
        ProcessedMessage = $Message.ToUpper()
        ProcessedAt = Get-Date
    }
}

# Test 3: Breakpoint demonstration
Write-Host "[INFO] Setting up breakpoint demonstration..." -ForegroundColor Blue
$result = Test-DebugFunction -Message "Hello from debugger"

# Test 4: Error handling debugging
try {
    Write-Host "[DEBUG] Testing error handling..." -ForegroundColor Magenta
    if ($TestType -eq "Error") {
        throw "Intentional error for debugging demonstration"
    }
    Write-Host "[SUCCESS] Error handling test passed" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Caught error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Template debugging simulation
$templateData = @{
    AssessmentName = "Debug Test Assessment"
    CompliancePercentage = 85
    RuleCount = 12
}

Write-Host "[DEBUG] Template data prepared for debugging:" -ForegroundColor Cyan
Write-Host "  Assessment: $($templateData.AssessmentName)" -ForegroundColor White
Write-Host "  Compliance: $($templateData.CompliancePercentage)%" -ForegroundColor White
Write-Host "  Rules: $($templateData.RuleCount)" -ForegroundColor White

# Test 6: Configuration debugging
$configPath = "config\settings.json"
if (Test-Path $configPath) {
    Write-Host "[DEBUG] Configuration file found: $configPath" -ForegroundColor Green
    $config = Get-Content $configPath | ConvertFrom-Json
    Write-Host "[DEBUG] Config loaded with $($config.PSObject.Properties.Count) properties" -ForegroundColor Green
} else {
    Write-Host "[WARN] Configuration file not found: $configPath" -ForegroundColor Yellow
}

Write-Host "[STIG] Debug Test Complete" -ForegroundColor Cyan
Write-Host "[INFO] Set breakpoints in VS Code and press F5 to debug this script!" -ForegroundColor Blue

return @{
    TestResult = "Success"
    DebugVariables = $debugVariables
    FunctionResult = $result
    TemplateData = $templateData
    CompletedAt = Get-Date
}

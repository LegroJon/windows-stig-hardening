<#
.SYNOPSIS
    Runs all tests for the Windows 11 STIG Assessment Tool

.DESCRIPTION
    Executes the complete test suite including unit tests, integration tests,
    and code coverage analysis. Generates reports in multiple formats.

.PARAMETER TestType
    Type of tests to run: All, Unit, Integration, Coverage

.PARAMETER OutputFormat
    Output format for test results: Console, NUnitXml, JUnitXml

.PARAMETER GenerateCoverage
    Generate code coverage reports

.PARAMETER GenerateReport
    Generate HTML test report

.EXAMPLE
    .\Run-Tests.ps1
    Run all tests with console output

.EXAMPLE
    .\Run-Tests.ps1 -TestType Unit -GenerateCoverage
    Run unit tests with coverage analysis

.EXAMPLE
    .\Run-Tests.ps1 -OutputFormat NUnitXml -GenerateReport
    Run all tests with XML output and HTML report
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Unit", "Integration", "Coverage")]
    [string]$TestType = "All",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "NUnitXml", "JUnitXml")]
    [string]$OutputFormat = "Console",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateCoverage,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Initialize
$ErrorActionPreference = "Stop"
$startTime = Get-Date

# Ensure we're in the project root
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot

Write-Host "Windows 11 STIG Assessment Tool - Test Runner" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Start Time: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "Test Type: $TestType" -ForegroundColor White
Write-Host "Output Format: $OutputFormat" -ForegroundColor White

# Check prerequisites
Write-Host "`nChecking Prerequisites..." -ForegroundColor Yellow

# Check if Pester is installed
try {
    $pesterModule = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $pesterModule -or $pesterModule.Version -lt [Version]"5.0.0") {
        throw "Pester 5.0+ is required. Run .\scripts\Install-TestingTools.ps1 first."
    }
    Write-Host "[SUCCESS] Pester $($pesterModule.Version) found" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Import Pester
Import-Module Pester -Force

# Create results directory
$resultsPath = Join-Path $projectRoot "tests\results"
if (-not (Test-Path $resultsPath)) {
    New-Item -Path $resultsPath -ItemType Directory -Force | Out-Null
}

# Configure Pester
$pesterConfig = New-PesterConfiguration

# Set output format
switch ($OutputFormat) {
    "Console" {
        $pesterConfig.Output.Verbosity = "Detailed"
    }
    "NUnitXml" {
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = Join-Path $resultsPath "TestResults.xml"
        $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    }
    "JUnitXml" {
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = Join-Path $resultsPath "TestResults.xml"
        $pesterConfig.TestResult.OutputFormat = "JUnitXml"
    }
}

# Configure code coverage if requested
if ($GenerateCoverage -or $TestType -eq "Coverage") {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.OutputPath = Join-Path $resultsPath "Coverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

    # Include all PowerShell files except tests
    $pesterConfig.CodeCoverage.Path = @(
        ".\rules\core\*.ps1",
        ".\rules\custom\*.ps1",
        ".\scripts\*.ps1"
    )

    Write-Host "[INFO] Code coverage enabled" -ForegroundColor Green
}

# Determine which tests to run
$testPaths = @()

switch ($TestType) {
    "All" {
        $testPaths = @(
            ".\tests\Rules.Tests.ps1",
            ".\tests\Scripts.Tests.ps1",
            ".\tests\Integration.Tests.ps1"
        )
    }
    "Unit" {
        $testPaths = @(
            ".\tests\Rules.Tests.ps1",
            ".\tests\Scripts.Tests.ps1"
        )
    }
    "Integration" {
        $testPaths = @(".\tests\Integration.Tests.ps1")
    }
    "Coverage" {
        $testPaths = @(
            ".\tests\Rules.Tests.ps1",
            ".\tests\Scripts.Tests.ps1"
        )
    }
}

# Filter to only existing test files
$testPaths = $testPaths | Where-Object { Test-Path $_ }

if ($testPaths.Count -eq 0) {
    Write-Host "[ERROR] No test files found to execute" -ForegroundColor Red
    exit 1
}

$pesterConfig.Run.Path = $testPaths

Write-Host "`nRunning Tests..." -ForegroundColor Yellow
Write-Host "Test Files: $($testPaths.Count)" -ForegroundColor White
foreach ($path in $testPaths) {
    Write-Host "  - $path" -ForegroundColor Gray
}

# Run the tests
try {
    $testResults = Invoke-Pester -Configuration $pesterConfig

    # Display results summary
    Write-Host "`nTest Results Summary" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan

    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Host "Execution Time: $($duration.ToString('mm\:ss\.fff'))" -ForegroundColor White
    Write-Host "Total Tests: $($testResults.TotalCount)" -ForegroundColor White
    Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { "Red" } else { "Green" })
    Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow

    if ($testResults.CodeCoverage) {
        $coveragePercent = [math]::Round(($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2)
        Write-Host "Code Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { "Green" } else { "Yellow" })
    }

    # Generate HTML report if requested
    if ($GenerateReport) {
        Write-Host "`nGenerating HTML Report..." -ForegroundColor Yellow

        $htmlReportPath = Join-Path $resultsPath "TestReport.html"

        # Simple HTML report
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>STIG Assessment Tool - Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2e86ab; color: white; padding: 20px; }
        .summary { background-color: #f0f0f0; padding: 15px; margin: 20px 0; }
        .passed { color: green; }
        .failed { color: red; }
        .skipped { color: orange; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Windows 11 STIG Assessment Tool - Test Results</h1>
        <p>Generated: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))</p>
    </div>

    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>Execution Time:</strong> $($duration.ToString('mm\:ss\.fff'))</p>
        <p><strong>Total Tests:</strong> $($testResults.TotalCount)</p>
        <p><strong>Passed:</strong> <span class="passed">$($testResults.PassedCount)</span></p>
        <p><strong>Failed:</strong> <span class="failed">$($testResults.FailedCount)</span></p>
        <p><strong>Skipped:</strong> <span class="skipped">$($testResults.SkippedCount)</span></p>
        $(if ($testResults.CodeCoverage) { "<p><strong>Code Coverage:</strong> $coveragePercent%</p>" })
    </div>

    <div class="details">
        <h2>Test Files Executed</h2>
        <ul>
            $(($testPaths | ForEach-Object { "<li>$_</li>" }) -join "`n")
        </ul>
    </div>
</body>
</html>
"@

        $htmlContent | Out-File -FilePath $htmlReportPath -Encoding UTF8
    Write-Host "[SUCCESS] HTML report generated: $htmlReportPath" -ForegroundColor Green
    }

    # Exit with appropriate code
    if ($testResults.FailedCount -gt 0) {
    Write-Host "`n[ERROR] Some tests failed" -ForegroundColor Red
        exit 1
    }
    else {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Host "`n[ERROR] Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

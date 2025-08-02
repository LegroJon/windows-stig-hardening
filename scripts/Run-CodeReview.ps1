# Run-CodeReview.ps1
# Automated Code Review and Quality Check Script for STIG Assessment Tool
# This script runs comprehensive code quality checks including syntax validation,
# security analysis, and compliance with project standards

param(
    [switch]$Verbose,
    [switch]$QuickScan,
    [string]$OutputPath = ".\reports\code-review-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Initialize results tracking
$reviewResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ProjectPath = (Get-Location).Path
    TotalFiles = 0
    Issues = @()
    Summary = @{
        Critical = 0
        High = 0
        Medium = 0
        Low = 0
        Info = 0
    }
}

Write-Host "[STIG] Automated Code Review Starting" -ForegroundColor Cyan
Write-Host "[INFO] Scanning Windows 11 STIG Assessment Tool..." -ForegroundColor Yellow

# Function to add issue to results
function Add-ReviewIssue {
    param(
        [string]$File,
        [string]$Line,
        [string]$Severity,
        [string]$Category,
        [string]$Description,
        [string]$Recommendation
    )

    $issue = @{
        File = $File
        Line = $Line
        Severity = $Severity
        Category = $Category
        Description = $Description
        Recommendation = $Recommendation
    }

    $reviewResults.Issues += $issue
    $reviewResults.Summary[$Severity]++

    $color = switch ($Severity) {
        "Critical" { "Red" }
        "High" { "Magenta" }
        "Medium" { "Yellow" }
        "Low" { "White" }
        "Info" { "Gray" }
    }

    if ($Verbose) {
        Write-Host "[$Severity] $File : $Description" -ForegroundColor $color
    }
}

# 1. PowerShell Syntax Validation
Write-Host "[RUNNING] PowerShell syntax validation..." -ForegroundColor Green

$psFiles = Get-ChildItem -Path "." -Filter "*.ps1" -Recurse | Where-Object { $_.FullName -notlike "*\node_modules\*" }
$reviewResults.TotalFiles += $psFiles.Count

foreach ($file in $psFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null

        if ($errors) {
            foreach ($error in $errors) {
                Add-ReviewIssue -File $file.FullName -Line $error.Token.StartLine -Severity "High" -Category "Syntax" -Description "PowerShell syntax error: $($error.Message)" -Recommendation "Fix syntax error before deployment"
            }
        }

        # Check for Unicode characters (project-specific rule)
        if ($content -match "[^\x00-\x7F]") {
            $unicodeMatches = [regex]::Matches($content, "[^\x00-\x7F]")
            foreach ($match in $unicodeMatches) {
                $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
                Add-ReviewIssue -File $file.FullName -Line $lineNum -Severity "Critical" -Category "Unicode" -Description "Unicode character detected: '$($match.Value)'" -Recommendation "Replace with ASCII equivalent using project standards"
            }
        }

    } catch {
        Add-ReviewIssue -File $file.FullName -Line "N/A" -Severity "High" -Category "Access" -Description "Cannot read file: $($_.Exception.Message)" -Recommendation "Check file permissions and encoding"
    }
}

# 2. Security Analysis
Write-Host "[RUNNING] Security analysis..." -ForegroundColor Green

foreach ($file in $psFiles) {
    try {
        $content = Get-Content $file.FullName -Raw

        # Check for potential security issues
        $securityPatterns = @{
            "Invoke-Expression" = @{ Severity = "High"; Description = "Use of Invoke-Expression detected"; Recommendation = "Avoid Invoke-Expression, use safer alternatives" }
            "Add-Type.*-TypeDefinition" = @{ Severity = "Medium"; Description = "Dynamic type compilation detected"; Recommendation = "Review code injection risks" }
            "Start-Process.*-Credential" = @{ Severity = "Medium"; Description = "Credential usage in Start-Process"; Recommendation = "Ensure credentials are handled securely" }
            "\$ExecutionContext" = @{ Severity = "Low"; Description = "ExecutionContext usage detected"; Recommendation = "Review for potential misuse" }
            "ConvertTo-SecureString.*-AsPlainText" = @{ Severity = "High"; Description = "Plain text to SecureString conversion"; Recommendation = "Avoid plain text passwords" }
        }

        foreach ($pattern in $securityPatterns.Keys) {
            if ($content -match $pattern) {
                $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                foreach ($match in $matches) {
                    $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
                    $config = $securityPatterns[$pattern]
                    Add-ReviewIssue -File $file.FullName -Line $lineNum -Severity $config.Severity -Category "Security" -Description $config.Description -Recommendation $config.Recommendation
                }
            }
        }

    } catch {
        Add-ReviewIssue -File $file.FullName -Line "N/A" -Severity "Low" -Category "Analysis" -Description "Security scan failed: $($_.Exception.Message)" -Recommendation "Manual security review required"
    }
}

# 3. Project Standards Compliance
Write-Host "[RUNNING] Project standards compliance..." -ForegroundColor Green

foreach ($file in $psFiles) {
    try {
        $content = Get-Content $file.FullName -Raw

        # Check for proper ASCII prefixes
        $writeHostPattern = 'Write-Host\s+"([^"]*)"'
        $matches = [regex]::Matches($content, $writeHostPattern)

        foreach ($match in $matches) {
            $message = $match.Groups[1].Value
            $validPrefixes = @("[STIG]", "[SUCCESS]", "[ERROR]", "[WARNING]", "[INFO]", "[ADMIN]", "[SECURITY]", "[RUNNING]", "[REPORT]", "[SUMMARY]", "[NEXT]", "[MANUAL]", "[RETRY]", "[COMPLETE]")

            $hasValidPrefix = $false
            foreach ($prefix in $validPrefixes) {
                if ($message.StartsWith($prefix)) {
                    $hasValidPrefix = $true
                    break
                }
            }

            if (-not $hasValidPrefix -and $message -notmatch "^[\s]*$") {
                $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
                Add-ReviewIssue -File $file.FullName -Line $lineNum -Severity "Medium" -Category "Standards" -Description "Write-Host without proper ASCII prefix: '$message'" -Recommendation "Use approved ASCII prefixes: [STIG], [SUCCESS], [ERROR], etc."
            }
        }

        # Check for proper function naming (Test- prefix for rule functions)
        if ($file.FullName -like "*\rules\*") {
            $functionPattern = 'function\s+([^\s\{]+)'
            $matches = [regex]::Matches($content, $functionPattern)

            foreach ($match in $matches) {
                $functionName = $match.Groups[1].Value
                if (-not $functionName.StartsWith("Test-")) {
                    $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
                    Add-ReviewIssue -File $file.FullName -Line $lineNum -Severity "Medium" -Category "Standards" -Description "Rule function without Test- prefix: '$functionName'" -Recommendation "Rule functions should start with 'Test-' prefix"
                }
            }
        }

    } catch {
        Add-ReviewIssue -File $file.FullName -Line "N/A" -Severity "Low" -Category "Standards" -Description "Standards check failed: $($_.Exception.Message)" -Recommendation "Manual standards review required"
    }
}

# 4. Configuration File Validation
Write-Host "[RUNNING] Configuration file validation..." -ForegroundColor Green

$configFiles = Get-ChildItem -Path ".\config" -Filter "*.json" -ErrorAction SilentlyContinue
foreach ($file in $configFiles) {
    try {
        $jsonContent = Get-Content $file.FullName -Raw | ConvertFrom-Json
        Add-ReviewIssue -File $file.FullName -Line "N/A" -Severity "Info" -Category "Config" -Description "JSON configuration file validated successfully" -Recommendation "No action required"
    } catch {
        Add-ReviewIssue -File $file.FullName -Line "N/A" -Severity "High" -Category "Config" -Description "Invalid JSON format: $($_.Exception.Message)" -Recommendation "Fix JSON syntax errors"
    }
}

# 5. Quick MCP Server Health Check (if not QuickScan)
if (-not $QuickScan) {
    Write-Host "[RUNNING] MCP server integration check..." -ForegroundColor Green

    if (Test-Path ".\mcp-server\package.json") {
        try {
            $packageJson = Get-Content ".\mcp-server\package.json" | ConvertFrom-Json
            if ($packageJson.dependencies) {
                Add-ReviewIssue -File ".\mcp-server\package.json" -Line "N/A" -Severity "Info" -Category "Dependencies" -Description "MCP server dependencies found: $($packageJson.dependencies.PSObject.Properties.Count) packages" -Recommendation "Regularly update dependencies for security"
            }
        } catch {
            Add-ReviewIssue -File ".\mcp-server\package.json" -Line "N/A" -Severity "Medium" -Category "Dependencies" -Description "Cannot parse MCP server package.json" -Recommendation "Verify package.json format"
        }
    }
}

# Generate Summary Report
Write-Host "`n[REPORT] Code Review Summary" -ForegroundColor Cyan
Write-Host "Files Scanned: $($reviewResults.TotalFiles)" -ForegroundColor White
Write-Host "Total Issues: $($reviewResults.Issues.Count)" -ForegroundColor White
Write-Host "Critical: $($reviewResults.Summary.Critical)" -ForegroundColor Red
Write-Host "High: $($reviewResults.Summary.High)" -ForegroundColor Magenta
Write-Host "Medium: $($reviewResults.Summary.Medium)" -ForegroundColor Yellow
Write-Host "Low: $($reviewResults.Summary.Low)" -ForegroundColor White
Write-Host "Info: $($reviewResults.Summary.Info)" -ForegroundColor Gray

# Save detailed report
try {
    $reviewResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "[SUCCESS] Detailed report saved to: $OutputPath" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to save report: $($_.Exception.Message)" -ForegroundColor Red
}

# Exit with appropriate code
$exitCode = 0
if ($reviewResults.Summary.Critical -gt 0) {
    $exitCode = 3
    Write-Host "[ERROR] Critical issues found - immediate attention required" -ForegroundColor Red
} elseif ($reviewResults.Summary.High -gt 0) {
    $exitCode = 2
    Write-Host "[WARNING] High priority issues found - review recommended" -ForegroundColor Yellow
} elseif ($reviewResults.Summary.Medium -gt 0) {
    $exitCode = 1
    Write-Host "[INFO] Medium priority issues found - consider reviewing" -ForegroundColor Yellow
} else {
    Write-Host "[SUCCESS] No critical issues found" -ForegroundColor Green
}

Write-Host "[COMPLETE] Code review completed with exit code: $exitCode" -ForegroundColor Cyan
exit $exitCode

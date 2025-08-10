<#
.SYNOPSIS
    Validates PowerShell scripts for Unicode character issues

.DESCRIPTION
    Scans PowerShell scripts (.ps1 files) for problematic Unicode characters
    that can cause parsing errors. This tool helps catch issues before they
    cause runtime problems.

.PARAMETER Path
    Path to scan for PowerShell files. Defaults to current directory.

.PARAMETER Fix
    Automatically fix common Unicode character issues

.EXAMPLE
    .\Validate-PowerShellSyntax.ps1
    Scan current directory for Unicode issues

.EXAMPLE
    .\Validate-PowerShellSyntax.ps1 -Path ".\scripts" -Fix
    Scan scripts folder and automatically fix issues
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [switch]$Fix
)

# Define problematic Unicode characters and their replacements
$UnicodeReplacements = @{
    "[UNICODE-SHIELD]"    = "[STIG]"
    "[UNICODE-CHECK]"     = "[SUCCESS]"
    "[UNICODE-X]"         = "[ERROR]"
    "[UNICODE-WARNING]"   = "[WARNING]"
    "[UNICODE-CHART]"     = "[REPORT]"
    "[UNICODE-ROCKET]"    = "[RUNNING]"
    # Deprecated targets below mapped to nearest approved prefix or neutral [INFO]
    "[UNICODE-LIGHTNING]" = "[RUNNING]"   # formerly QUICK
    "[UNICODE-CLIPBOARD]" = "[REPORT]"    # formerly ALL
    "[UNICODE-GRAPH]"     = "[REPORT]"    # formerly CSV
    "[UNICODE-WRENCH]"    = "[INFO]"      # formerly JSON
    "[UNICODE-WAVE]"      = "[INFO]"      # formerly EXIT
    "[UNICODE-FOLDER]"    = "[INFO]"
    "[UNICODE-TARGET]"    = "[INFO]"
    "[UNICODE-PAGE]"      = "[INFO]"
}

function Test-PowerShellSyntax {
    param([string]$FilePath)

    try {
        # Parse the PowerShell script
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)

        if ($errors.Count -gt 0) {
            return @{
                Valid = $false
                Errors = $errors
            }
        }

        return @{
            Valid = $true
            Errors = @()
        }
    }
    catch {
        return @{
            Valid = $false
            Errors = @($_)
        }
    }
}

function Find-UnicodeCharacters {
    param([string]$FilePath)

    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $issues = @()

    foreach ($unicode in $UnicodeReplacements.Keys) {
        if ($content.Contains($unicode)) {
            $issues += @{
                Character = $unicode
                Replacement = $UnicodeReplacements[$unicode]
                File = $FilePath
            }
        }
    }

    return $issues
}

function Fix-UnicodeCharacters {
    param(
        [string]$FilePath,
        [array]$Issues
    )

    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $modified = $false

    foreach ($issue in $Issues) {
        if ($content.Contains($issue.Character)) {
            $content = $content.Replace($issue.Character, $issue.Replacement)
            $modified = $true
            Write-Host "  Fixed: $($issue.Character) -> $($issue.Replacement)" -ForegroundColor Green
        }
    }

    if ($modified) {
        Set-Content -Path $FilePath -Value $content -Encoding UTF8
        Write-Host "  File updated: $FilePath" -ForegroundColor Cyan
    }
}

# Main execution
Write-Host "[STIG] PowerShell Script Unicode Validator" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Find all PowerShell files
$psFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.ps1" -File

if ($psFiles.Count -eq 0) {
    Write-Host "[INFO] No PowerShell files found in: $Path" -ForegroundColor Yellow
    exit 0
}

Write-Host "[INFO] Found $($psFiles.Count) PowerShell files to validate" -ForegroundColor Green

$totalIssues = 0
$filesWithIssues = 0

foreach ($file in $psFiles) {
    Write-Host "`n[RUNNING] Scanning $($file.Name)" -ForegroundColor White

    # Check for Unicode characters
    $unicodeIssues = Find-UnicodeCharacters -FilePath $file.FullName

    if ($unicodeIssues.Count -gt 0) {
        $filesWithIssues++
        $totalIssues += $unicodeIssues.Count

        Write-Host "  [WARNING] Found $($unicodeIssues.Count) Unicode character(s)" -ForegroundColor Yellow

        foreach ($issue in $unicodeIssues) {
            Write-Host "    - '$($issue.Character)' should be '$($issue.Replacement)'" -ForegroundColor Red
        }

        if ($Fix) {
            Write-Host "  [RUNNING] Applying automatic fixes..." -ForegroundColor Cyan
            Fix-UnicodeCharacters -FilePath $file.FullName -Issues $unicodeIssues
        }
    }

    # Test PowerShell syntax
    $syntaxResult = Test-PowerShellSyntax -FilePath $file.FullName

    if (-not $syntaxResult.Valid) {
        Write-Host "  [ERROR] PowerShell syntax errors found:" -ForegroundColor Red
        foreach ($error in $syntaxResult.Errors) {
            Write-Host "    - $($error.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [SUCCESS] PowerShell syntax is valid" -ForegroundColor Green
    }
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "[SUMMARY] Validation Complete" -ForegroundColor Cyan
Write-Host "Files scanned: $($psFiles.Count)" -ForegroundColor White
Write-Host "Files with Unicode issues: $filesWithIssues" -ForegroundColor $(if ($filesWithIssues -gt 0) { "Yellow" } else { "Green" })
Write-Host "Total Unicode issues: $totalIssues" -ForegroundColor $(if ($totalIssues -gt 0) { "Red" } else { "Green" })

if ($totalIssues -gt 0 -and -not $Fix) {
    Write-Host "`n[NEXT] Run with -Fix parameter to automatically resolve Unicode issues" -ForegroundColor Cyan
}

if ($totalIssues -eq 0) {
    Write-Host "`n[SUCCESS] All PowerShell files are Unicode-clean!" -ForegroundColor Green
}

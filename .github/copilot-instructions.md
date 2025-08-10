# [STIG] Copilot Instructions for PowerShell STIG Assessment Tool

You are assisting in building a modular, CLI-based PowerShell tool for assessing STIG compliance on Windows 11 systems. The tool does not automatically remediate settings, but instead scans for compliance and provides human-readable remediation instructions.

## 🎉 PROJECT STATUS: STABILIZATION PHASE ✅
**Date Updated**: January 29, 2025
**Current Phase**: Post-MCP Cleanup, Core Functionality Stable  
**Status**: 12 STIG rules implemented, Unicode issues resolved, MCP components removed
**Impact**: Simplified architecture, PowerShell scripts execute correctly, CI/CD operational

## ✅ General Project Guidelines
- Target: Windows 11 only (no support for Windows Server or Windows 10)
- PowerShell is the primary language
- All rule logic should be modular and placed in individual `.ps1` scripts
- The tool should run with admin privileges and warn if not elevated
- Focus on detection, not enforcement
- **Execution Environment**: Use PowerShell terminal for all script testing and execution
- **Command Preference**: Use PowerShell commands over cmd.exe when possible

## [ENFORCED] PowerShell Coding Standards

### Unicode Character Policy - STRICTLY ENFORCED
**STATUS**: ✅ **RESOLVED** - All Unicode characters have been replaced with ASCII equivalents

**MANDATORY RULES** (Zero tolerance policy):
- **NEVER** use Unicode characters (emojis, symbols) in PowerShell scripts
- **ALWAYS** use ASCII text prefixes for logging and output
- **VALIDATE** all scripts with `scripts\Validate-PowerShellSyntax.ps1` before committing

**✅ APPROVED ASCII Prefixes** (Use these ONLY):
```powershell
[STIG]        # For tool branding and main messages
[SUCCESS]     # For successful operations  
[ERROR]       # For error conditions
[WARNING]     # For warning messages
[INFO]        # For informational messages
[ADMIN]       # For admin privilege messages
[SECURITY]    # For security-related messages
[RUNNING]     # For operations in progress
[REPORT]      # For reporting operations
[SUMMARY]     # For summary information
[NEXT]        # For next steps
[MANUAL]      # For manual intervention required
[RETRY]       # For retry operations
[COMPLETE]    # For completion messages
```

**❌ BANNED Characters** (Will cause parsing errors):
- Emojis: `🛡️`, `✅`, `❌`, `⚠️`, `📊`, `🚀`, `📁`, `🎯`, `⚡`, etc.
- Unicode symbols: `→`, `←`, `↑`, `↓`, `▶`, `◀`, etc.

**✅ CORRECT Examples:**
```powershell
# Main tool branding
Write-Host "[STIG] Windows 11 STIG Assessment Tool" -ForegroundColor Cyan

# Success messages
Write-Host "[SUCCESS] Assessment completed successfully" -ForegroundColor Green

# Error handling
Write-Host "[ERROR] Failed to access registry key" -ForegroundColor Red

# Admin privilege warnings
Write-Host "[ADMIN] Administrator privileges required" -ForegroundColor Yellow
```

### String Formatting Rules
- Always use proper quote termination
- Escape special characters in strings
- Use backticks for line continuation in long strings
- Prefer single quotes for simple strings, double quotes when interpolation needed

### Code Quality Requirements
- **Mandatory**: Run `scripts\Validate-PowerShellSyntax.ps1` before any commit
- **Required**: All scripts must pass syntax validation with zero Unicode issues
- **Standard**: Use consistent ASCII prefixes for all user-facing messages
- **Best Practice**: Include proper error handling in all functions

## 📂 Project Structure

| Folder | Purpose |
|--------|---------|
| `rules/core/` | Official STIG rule checks |
| `rules/custom/` | User-defined plugin rules |
| `reports/` | Exported reports (HTML, PDF, CSV, JSON) |
| `logs/` | Scan and execution logs |
| `scripts/` | CLI entry points (e.g., run scan, export) |
| `tests/` | Unit tests using Pester |
| `config/` | JSON configuration files |
| `.github/` | Copilot instructions and GitHub metadata |

## 🔁 Rule Format Guidelines
- Rule script functions should start with `Test-` (e.g., `Test-DisableSMBv1`)
- Each rule must return an object with:
  - `RuleID` — e.g., "WN11-SO-000001"
  - `Status` — `"Compliant"` or `"Non-Compliant"`
  - `Evidence` — supporting system output
  - `FixText` — guidance on how to remediate

## 🧪 Example Rule Script

```powershell
function Test-DisableSMBv1 {
    $smb = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol"
    return @{
        RuleID   = "WN11-SO-000001"
        Status   = if ($smb.State -eq "Disabled") { "Compliant" } else { "Non-Compliant" }
        Evidence = $smb.State
        FixText  = "Run: Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol"
    }
}
```

## 🔧 Common Issues and Solutions

### PowerShell Parsing Errors
**Problem**: "The string is missing the terminator" errors
**Cause**: Unicode characters in strings (emojis, special symbols)
**Solution**: Replace all Unicode characters with ASCII text equivalents

```powershell
# Replace these patterns:
🛡️ → [STIG]
✅ → [SUCCESS] or [PASS]
❌ → [ERROR] or [FAIL]
⚠️ → [WARNING]
📊 → [REPORT] or [DATA]
🚀 → [RUNNING] or [START]
📁 → [FOLDER] or [FILES]
🎯 → [TARGET] or [CRITICAL]
⚡ → [QUICK] or [FAST]
```

**VALIDATION COMMAND**:
```powershell
# Run this before any code commit
.\scripts\Validate-PowerShellSyntax.ps1
```

### Script Execution Issues
**Problem**: Scripts won't run or show access denied
**Cause**: Execution policy restrictions
**Solution**: Use `-ExecutionPolicy Bypass` or set policy appropriately

**Problem**: Missing admin privileges
**Cause**: UAC restrictions on Windows
**Solution**: Use `-RequestAdmin` parameter or run PowerShell as Administrator

**Problem**: Terminal output truncated or commands fail
**Cause**: Running PowerShell commands through cmd.exe instead of PowerShell
**Solution**: Use PowerShell terminal for PowerShell scripts and commands

### Execution Environment Guidelines
**When to use PowerShell terminal:**
- Running any `.ps1` PowerShell scripts
- Testing PowerShell syntax and validation
- Administrative tasks requiring elevated privileges
- Complex PowerShell commands with multiple parameters

**When to use Command Prompt (cmd.exe):**
- Simple file operations (copy, move, delete)
- Running batch files (.bat, .cmd)
- Directory navigation and basic file listing
- Launching external executables

**Preferred approach for this project:**
- Primary: Use PowerShell terminal for all script execution
- Fallback: Use cmd.exe only for basic file operations when PowerShell is unavailable

### File Organization Standards
- All user-facing scripts go in `scripts/` folder
- Rule implementations go in `rules/core/` or `rules/custom/`
- Documentation goes in `docs/` folder
- Tests go in `tests/` folder
- Keep root directory clean with only essential files

### Quality Assurance
- Always test PowerShell scripts before committing
- Use ASCII characters only in script output
- Validate string termination and escaping
- Ensure proper error handling in all functions

## 💻 Terminal and Execution Best Practices

### PowerShell vs Command Prompt Usage
This project is PowerShell-focused, so prefer PowerShell execution environment:

**✅ PowerShell Terminal Commands:**
```powershell
# Script execution
.\scripts\Start-STIGAssessment.ps1 -RequestAdmin
.\Launch-Assessment.ps1

# Testing and validation
Get-Help .\scripts\Start-STIGAssessment.ps1 -Detailed
Test-Path ".\config\settings.json"

# Administrative tasks
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# File operations (PowerShell style)
Get-ChildItem -Recurse -Filter "*.ps1"
Copy-Item -Path "source.ps1" -Destination "backup.ps1"
```

**❌ Avoid cmd.exe for PowerShell operations:**
```cmd
# These can cause issues with PowerShell scripts
powershell.exe -File script.ps1
powershell -Command "complex command with quotes"
```

### Error Troubleshooting Commands
When debugging PowerShell syntax issues:

```powershell
# Test PowerShell syntax
$errors = $null
[System.Management.Automation.PSParser]::Tokenize((Get-Content "script.ps1" -Raw), [ref]$errors)
if ($errors) { $errors | Format-Table }

# Check for Unicode characters
Get-Content "script.ps1" -Raw | Select-String -Pattern "[^\x00-\x7F]"

# Validate execution policy
Get-ExecutionPolicy -List
```

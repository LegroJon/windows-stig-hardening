# 🛡️ Copilot Instructions for PowerShell STIG Assessment Tool

You are assisting in building a modular, CLI-based PowerShell tool for assessing STIG compliance on Windows 11 systems. The tool does not automatically remediate settings, but instead scans for compliance and provides human-readable remediation instructions.

## ✅ General Project Guidelines
- Target: Windows 11 only (no support for Windows Server or Windows 10)
- PowerShell is the primary language
- All rule logic should be modular and placed in individual `.ps1` scripts
- The tool should run with admin privileges and warn if not elevated
- Focus on detection, not enforcement

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

# CLI Scripts

This folder contains the main entry points for the STIG assessment tool.

## Main Scripts
- **Start-STIGAssessment.ps1** - Main scanner entry point
- **Export-STIGReport.ps1** - Report generation utility
- **Import-CustomRules.ps1** - Custom rule management
- **Test-Prerequisites.ps1** - System requirement checker

## Usage Examples
```powershell
# Run full STIG assessment
.\Start-STIGAssessment.ps1 -OutputPath "C:\Reports"

# Export specific format
.\Export-STIGReport.ps1 -InputPath ".\reports\latest.json" -Format HTML

# Test system prerequisites
.\Test-Prerequisites.ps1 -Verbose
```

All scripts require administrative privileges to run properly.

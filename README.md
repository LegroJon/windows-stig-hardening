# 🛡️ Windows 11 STIG Assessment Tool

A modular, CLI-based PowerShell tool for assessing DISA STIG compliance on Windows 11 systems. This tool focuses on **detection and assessment** rather than automatic remediation, providing detailed compliance reports with human-readable remediation guidance.

## 🎯 Features

- ✅ **Windows 11 STIG Compliance Assessment** - Comprehensive checks against DISA STIG requirements
- 🔍 **Detection-Focused** - Scans for compliance without making system changes
- 📊 **Multiple Report Formats** - HTML, PDF, CSV, and JSON output options
- 🧩 **Modular Architecture** - Individual PowerShell scripts for each STIG rule
- 🔧 **Extensible** - Support for custom organizational rules
- 📋 **Detailed Remediation** - Clear, actionable guidance for each finding
- 🚀 **CLI-Based** - Scriptable and automation-friendly

## 📋 Prerequisites

- **Operating System**: Windows 11 (Enterprise, Professional, or Education)
- **PowerShell**: Version 5.1 or higher (PowerShell 7+ recommended)
- **Privileges**: Administrator rights required for system assessment
- **Optional**: Pester module for running tests

## 🚀 Quick Start

### 1. Clone the Repository
```powershell
git clone https://github.com/LegroJon/windows-stig-hardening.git
cd windows-stig-hardening
```

### 2. Run Assessment
```powershell
# Basic assessment (Coming Soon)
.\scripts\Start-STIGAssessment.ps1

# With custom output location
.\scripts\Start-STIGAssessment.ps1 -OutputPath "C:\Reports"

# Include custom rules
.\scripts\Start-STIGAssessment.ps1 -IncludeCustomRules
```

### 3. View Results
Reports are generated in the `reports/` folder with timestamps. Open the HTML report for an interactive view.

## 📂 Project Structure

```
windows-stig-hardening/
├── 📁 rules/
│   ├── 📁 core/              # Official DISA STIG rule checks
│   │   ├── WN11-SO-000001.ps1    # Example: Disable SMBv1
│   │   └── ...
│   └── 📁 custom/            # Custom organizational rules
├── 📁 scripts/               # CLI entry points
│   ├── Start-STIGAssessment.ps1  # Main assessment script
│   ├── Export-STIGReport.ps1     # Report generation
│   └── Test-Prerequisites.ps1    # System requirements check
├── 📁 config/                # Configuration files
│   ├── settings.json             # Main tool settings
│   └── rules.json               # Rule metadata
├── 📁 reports/               # Generated assessment reports
├── 📁 logs/                  # Execution and error logs
├── 📁 tests/                 # Pester unit tests
└── 📁 .github/               # GitHub metadata and Copilot instructions
```

## 🔧 Configuration

Edit `config/settings.json` to customize:

- **Scanning Options**: Parallel execution, timeouts, thread limits
- **Reporting**: Default formats, content inclusion
- **Logging**: Verbosity levels, file rotation
- **Rules**: Paths, inclusion/exclusion lists

## 📝 Rule Format

Each STIG rule follows a standardized format:

```powershell
function Test-[RuleName] {
    # Assessment logic here
    return @{
        RuleID   = "WN11-XX-000000"    # STIG identifier
        Status   = "Compliant|Non-Compliant|Error"
        Evidence = "Supporting data"
        FixText  = "Remediation guidance"
    }
}
```

## 📊 Report Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| **HTML** | Interactive web report | Review and analysis |
| **PDF** | Executive summary | Documentation and compliance |
| **CSV** | Tabular data | Spreadsheet analysis |
| **JSON** | Raw structured data | Integration with other tools |

## 🧪 Testing

Run the test suite to validate rule logic:

```powershell
# Install Pester (if not already installed)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run all tests
Invoke-Pester

# Run specific test file
Invoke-Pester -Path ".\tests\Rules.Tests.ps1"
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/new-rule`)
3. **Follow** the rule format guidelines in `.github/copilot-instructions.md`
4. **Add tests** for new rules
5. **Submit** a pull request

### Adding New Rules

1. Create rule script in `rules/core/` or `rules/custom/`
2. Follow naming convention: `WN11-XX-000000.ps1`
3. Implement `Test-[RuleName]` function
4. Add corresponding Pester tests
5. Update rule metadata in `config/rules.json`

## 📚 Resources

- [DISA STIG Library](https://public.cyber.mil/stigs/)
- [Windows 11 STIG Documentation](https://public.cyber.mil/stigs/downloads/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Pester Testing Framework](https://pester.dev/)

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🚧 Development Status

**Current Phase**: Initial Development
- ✅ Project structure established
- ✅ Configuration framework ready
- ✅ Example rule implemented
- 🔄 Core CLI scripts (In Progress)
- 🔄 Test framework (Planned)
- 🔄 Additional STIG rules (Planned)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/LegroJon/windows-stig-hardening/issues)
- **Discussions**: [GitHub Discussions](https://github.com/LegroJon/windows-stig-hardening/discussions)

---

> **⚠️ Disclaimer**: This tool is for assessment purposes only. Always test changes in a non-production environment before implementing STIG recommendations on production systems.

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

> 📖 **Complete Setup Instructions**: See [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md) for detailed installation steps

## 🚀 Quick Start

### 1. Clone the Repository
```powershell
git clone https://github.com/LegroJon/windows-stig-hardening.git
cd windows-stig-hardening
```

### 2. Run Assessment

**Option A: Quick Menu (Recommended)**
```powershell
# Launch the interactive assessment menu
.\Launch-Assessment.ps1
```

**Option B: Direct CLI Access**
```powershell
# Run quick assessment with interactive menu
.\scripts\Quick-Assessment.ps1

# Run advanced CLI tool directly
.\scripts\Start-STIGAssessment.ps1 -RequestAdmin

# Generate specific report format
.\scripts\Start-STIGAssessment.ps1 -Format HTML -RequestAdmin

# Filter critical rules only
.\scripts\Start-STIGAssessment.ps1 -RuleFilter "CAT I" -Format ALL -RequestAdmin
```

### 3. View Results
Reports are generated in the `reports/` folder with timestamps. Open the HTML report for an interactive view.

## 📂 Project Structure

```
windows-stig-hardening/
├── 📁 rules/
│   ├── 📁 core/                    # Official DISA STIG rule checks
│   │   ├── WN11-SO-000001.ps1          # SMBv1 Protocol disabled
│   │   ├── WN11-SO-000005.ps1          # User Account Control settings  
│   │   ├── WN11-SO-000010.ps1          # Windows Firewall enabled
│   │   ├── WN11-SO-000015.ps1          # Data Execution Prevention
│   │   ├── WN11-SO-000020.ps1          # BitLocker Drive Encryption
│   │   ├── WN11-SO-000025.ps1          # Telnet Client disabled
│   │   ├── WN11-SO-000030.ps1          # Windows Defender enabled
│   │   └── ...                         # Additional STIG rules
│   └── 📁 custom/                  # Custom organizational rules
├── 📁 scripts/                     # All executable scripts
│   ├── Start-STIGAssessment.ps1        # Main CLI assessment engine
│   ├── Quick-Assessment.ps1            # Interactive menu launcher
│   ├── Run-STIG-Assessment-Admin.ps1   # Admin elevation helper
│   ├── Run-STIG-Assessment-Admin.bat   # Batch admin launcher
│   ├── Test-Admin.ps1                  # Admin privilege checker
│   ├── Request-AdminRights.ps1         # UAC elevation tool
│   └── ...                             # Additional utility scripts
├── 📁 docs/                        # Complete documentation
│   ├── SETUP_GUIDE.md                 # Installation instructions
│   ├── TESTING_EXPLAINED.md           # Development vs compliance testing
│   ├── DEVELOPMENT_PLAN.md            # Technical roadmap
│   └── STIG_RESOURCES.md              # Official DISA references
├── 📁 config/                      # Configuration files
│   ├── settings.json                   # Main tool settings
│   └── rules.json                     # Rule metadata
├── 📁 reports/                     # Generated assessment reports
├── 📁 logs/                        # Execution and error logs
├── 📁 tests/                       # Pester unit tests
│   └── test-syntax.ps1                # PowerShell syntax validation
├── 📁 .github/                     # GitHub metadata and Copilot instructions
├── Launch-Assessment.ps1           # Main entry point launcher
└── README.md                       # This documentation
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

The tool has two separate testing systems:
- **Development Tests** (Pester): Validates code logic during development
- **STIG Assessment**: Tests real Windows security compliance

```powershell
# Run development tests (Pester)
.\scripts\Run-Tests.ps1

# Run STIG compliance assessment
.\scripts\Start-STIGAssessment.ps1 -RequestAdmin
```

> 📖 **Understanding the Difference**: See [docs/TESTING_EXPLAINED.md](docs/TESTING_EXPLAINED.md) for complete details

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

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md) | Complete installation and setup instructions |
| [docs/TESTING_EXPLAINED.md](docs/TESTING_EXPLAINED.md) | Development tests vs STIG compliance assessment |
| [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) | Technical roadmap and architecture |
| [docs/STIG_RESOURCES.md](docs/STIG_RESOURCES.md) | Official DISA STIG references |

## 🔗 External Resources

- [DISA STIG Library](https://public.cyber.mil/stigs/)
- [Windows 11 STIG Documentation](https://public.cyber.mil/stigs/downloads/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Pester Testing Framework](https://pester.dev/)

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🚧 Development Status

**Current Phase**: Enhanced Reporting Complete ✅
- ✅ Project structure established
- ✅ Configuration framework ready
- ✅ **12 STIG rules implemented** (71% increase!)
- ✅ **Core CLI scripts functional** (Start-STIGAssessment.ps1, Quick-Assessment.ps1)
- ✅ **Multi-format reporting** (HTML, CSV, JSON)
- ✅ **Enhanced HTML Dashboard** (Executive styling, risk assessment, progress bars)
- ✅ **Performance timing** (Assessment duration tracking)
- ✅ **Testing framework complete** (Pester integration)
- ✅ **Real compliance assessment** (25% baseline established)
- ✅ **Admin privilege handling** (Multiple UAC approaches)
- 🔄 Performance optimization (Next Phase)
- 📋 Additional STIG rule expansion (Ongoing)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/LegroJon/windows-stig-hardening/issues)
- **Discussions**: [GitHub Discussions](https://github.com/LegroJon/windows-stig-hardening/discussions)

---

> **⚠️ Disclaimer**: This tool is for assessment purposes only. Always test changes in a non-production environment before implementing STIG recommendations on production systems.

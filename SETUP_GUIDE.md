# 🛠️ Windows 11 STIG Assessment Tool - Setup Guide

## Quick Start

1. **Clone/Download** the repository
2. **Run the automated installer**: `.\scripts\Install-TestingTools.ps1`
3. **Verify setup**: `.\scripts\Test-Prerequisites.ps1`
4. **Start development** or run assessments

---

## 📋 Prerequisites Check

### System Requirements
- ✅ **Windows 11** (any edition)
- ✅ **PowerShell 5.1+** (built into Windows 11)
- ❌ **Administrator Privileges** (recommended for full functionality)
- ✅ **Execution Policy** set to `Bypass` or `RemoteSigned`

### Required Testing Tools
- ✅ **Pester 5.0+** (PowerShell testing framework)
- ✅ **PSScriptAnalyzer** (code quality analysis)
- ⚠️ **Optional**: powershell-yaml, InvokeBuild

---

## 🚀 Installation Process

### Step 1: Install Testing Tools
```powershell
# Run the automated installer
.\scripts\Install-TestingTools.ps1

# If you see "NuGet provider is required" prompt:
# Answer: Y (Yes)

# If you see publisher trust prompts:
# Answer: A (Always run)
```

### Step 2: Verify Installation
```powershell
# Check system readiness
.\scripts\Test-Prerequisites.ps1

# Expected output should show PASS for most items
```

### Step 3: Request Admin Rights (Optional but Recommended)
```powershell
# Option A: Use our admin elevation script
.\scripts\Request-AdminRights.ps1

# Option B: Automatically elevate when running assessments
.\scripts\Start-STIGAssessment.ps1 -RequestAdmin

# Option C: Manual - Right-click PowerShell → "Run as Administrator"
```

---

## 🔍 Understanding Multiple Pester Versions

When you run `Get-Module -ListAvailable Pester`, you might see:

```
Name             Version
----             -------
Pester           5.7.1    ← This is what we use (modern)
Pester           3.4.0    ← Built-in Windows version (legacy)
```

**This is normal!** PowerShell automatically uses the highest version (5.7.1).

---

## 🛡️ Common Issues & Solutions

### Issue: "Execution policy restriction"
**Solution**: Run PowerShell commands with `-ExecutionPolicy Bypass`
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\scripts\Install-TestingTools.ps1"
```

### Issue: "Not running as administrator"
**Solutions**:

#### Option 1: Start PowerShell as Administrator (Recommended)
1. Press `Win + X` → Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
2. Or: Right-click PowerShell → "Run as Administrator"
3. Navigate to project: `cd "c:\Users\jonat\OneDrive\Desktop\E-Books\Cyber\windows-stig-hardening"`

#### Option 2: Self-Elevate Scripts (Automatic)
Our scripts can automatically request admin rights when needed:
```powershell
# Add this to any script that needs admin rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
```

#### Option 3: UAC Bypass for Development (Advanced)
For frequent development, you can temporarily modify UAC settings, but this is **not recommended** for security reasons.

- **Impact**: Some system-level STIG checks may not work without admin rights
- **Workaround**: Development and testing can proceed without admin rights

### Issue: "NuGet provider required"
**Solution**: Answer "Y" when prompted during installation
- This is a one-time setup requirement for PowerShell module management

### Issue: "Publisher not trusted"
**Solution**: Answer "A" (Always run) for Pester and PSScriptAnalyzer
- These are well-known, trusted PowerShell modules

---

## 📊 Current Project Status

### ✅ Completed Components
- [x] Project structure and documentation
- [x] Configuration system (`config/settings.json`, `config/rules.json`)
- [x] Testing framework (Pester integration)
- [x] Code quality tools (PSScriptAnalyzer)
- [x] CLI scripts foundation
- [x] Example STIG rule (`WN11-SO-000001.ps1`)
- [x] Prerequisites checker (`Test-Prerequisites.ps1`)

### 🚧 In Progress
- [ ] Rule engine implementation (discovery and execution)
- [ ] Additional STIG rules
- [ ] Report generation (JSON/HTML/CSV)

### 📋 Next Development Steps
1. **Implement Rule Engine** - Rule discovery and execution framework
2. **Add More STIG Rules** - 3-5 additional Windows 11 STIG checks
3. **Report Generation** - JSON export and HTML reporting
4. **Integration Testing** - End-to-end testing scenarios

---

## 🎯 Development Workflow

### For Contributors
1. **Setup**: Run `.\scripts\Install-TestingTools.ps1`
2. **Verify**: Run `.\scripts\Test-Prerequisites.ps1`
3. **Test**: Run `.\scripts\Run-Tests.ps1` before committing
4. **Code Quality**: Tests include PSScriptAnalyzer checks

### For Users
1. **Install**: Run the testing tools installer once
2. **Assess**: Use `.\scripts\Start-STIGAssessment.ps1` (when ready)
3. **Report**: Generate compliance reports in multiple formats

---

## 📁 Key Files Reference

| File | Purpose |
|------|---------|
| `scripts/Install-TestingTools.ps1` | One-time development setup |
| `scripts/Test-Prerequisites.ps1` | System readiness check |
| `scripts/Start-STIGAssessment.ps1` | Main assessment tool |
| `rules/core/WN11-SO-000001.ps1` | Example STIG rule |
| `tests/Run-Tests.ps1` | Execute all tests |
| `config/settings.json` | Tool configuration |
| `DEVELOPMENT_PLAN.md` | Detailed project roadmap |

---

## 💡 Pro Tips

- **Always run** `Test-Prerequisites.ps1` after setup changes
- **Use** `-ExecutionPolicy Bypass` if you encounter script restrictions
- **Check** `DEVELOPMENT_PLAN.md` for detailed technical architecture
- **Run tests** frequently during development: `.\scripts\Run-Tests.ps1`
- **Admin rights** are recommended but not required for development

---

*Last Updated: July 28, 2025*
*Next Milestone: Rule Engine Implementation*

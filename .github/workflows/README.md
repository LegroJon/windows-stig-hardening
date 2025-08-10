# [STIG] CI/CD Pipeline Documentation

This directory contains GitHub Actions workflows for automated testing, security analysis, and maintenance of the Windows 11 STIG Assessment Tool.

## 📋 Workflow Overview

| Workflow | File | Triggers | Purpose |
|----------|------|----------|---------|
| **CI/CD Pipeline** | `ci-cd.yml` | Push, PR, Release | Complete build and test pipeline |
| **Security Check** | `security-check.yml` | Weekly, Manual, Rules changes | Advanced security analysis |
| **Maintenance** | `maintenance.yml` | Monthly, Manual | Dependency and documentation updates |

---

## 🚀 CI/CD Pipeline (`ci-cd.yml`)

### **Triggers**
- **Push**: `main`, `develop`, `fix-*` branches
- **Pull Request**: targeting `main` branch  
- **Release**: published releases

### **Jobs Overview**

#### 1. **[VALIDATOR] PowerShell Syntax Check**
- ✅ Validates PowerShell syntax using `Validate-PowerShellSyntax.ps1`
- ✅ Checks for Unicode characters (strictly enforced)
- ✅ Runs on all `.ps1` files in `rules/core` and `scripts/`

#### 2. **[TESTING] Pester Unit Tests** 
- ✅ Installs Pester module
- ✅ Runs unit tests with code coverage
- ✅ Generates JUnit XML reports
- ✅ Uploads test artifacts

#### 3. **[SECURITY] STIG Rules Validation**
- ✅ Validates STIG rule structure and naming
- ✅ Checks for required function patterns (`Test-*`)
- ✅ Verifies required return properties (`RuleID`, `Status`, `Evidence`, `FixText`)
- ✅ Ensures proper RuleID format (`WN11-XX-000000`)

#### 4. **[DOCS] Documentation Validation**
- ✅ Checks for required documentation files
- ✅ Non-blocking warnings for missing docs

#### 5. **[SECURITY] Security Analysis**
- ✅ Scans for dangerous PowerShell patterns
- ✅ Reports security concerns without failing build
- ✅ Identifies potential vulnerabilities

#### 6. **[BUILD] Create Release Package**
- ✅ Triggers only on published releases
- ✅ Creates ZIP packages with all essential files
- ✅ Uploads release artifacts

#### 7. **[DEPLOY] PowerShell Gallery** *(Future)*
- 📋 Placeholder for PowerShell Gallery publishing
- 📋 Requires module manifest and API key setup

#### 8. **[REPORT] Workflow Summary**
- ✅ Generates comprehensive pipeline summary
- ✅ Shows status of all critical checks
- ✅ Color-coded results display

### **Environment Variables**
```yaml
env:
  POWERSHELL_TELEMETRY_OPTOUT: 1  # Disable telemetry for clean logs
```

---

## 🔒 Security Check (`security-check.yml`)

### **Triggers**
- **Schedule**: Weekly on Sundays at 2 AM UTC
- **Manual**: `workflow_dispatch` 
- **Push**: Changes to `rules/**` or `scripts/**`

### **Jobs Overview**

#### 1. **[SECURITY] Advanced Security Analysis**
- 🔴 **High-Risk Patterns**: Dynamic code execution, web downloads, hidden processes
- 🟡 **Medium-Risk Patterns**: Credential handling, plain text passwords
- 🔵 **Low-Risk Patterns**: Debug information, file operations
- ✅ **Best Practices**: Error handling, proper parameters

#### 2. **[STIG] STIG Compliance Validation**
- ✅ Validates STIG naming conventions
- ✅ Checks function structure and return format
- ✅ Ensures error handling presence
- ✅ Comprehensive compliance scoring

#### 3. **[QUALITY] Code Quality Metrics**
- 📊 Lines of code analysis
- 📊 Function complexity estimation  
- 📊 Documentation coverage percentage
- 📊 Error handling coverage percentage
- 📊 Overall quality scoring (0-100)

### **Quality Scoring**
- **Documentation**: 30% weight
- **Error Handling**: 40% weight  
- **Complexity**: 30% weight
- **Threshold**: 60% minimum recommended

---

## 🔧 Maintenance (`maintenance.yml`)

### **Triggers**
- **Schedule**: Monthly on 1st at 6 AM UTC
- **Manual**: `workflow_dispatch`

### **Jobs Overview**

#### 1. **[MAINTENANCE] Update PowerShell Modules**
- ✅ Checks Pester and other project modules
- ✅ Compares current vs latest versions
- ✅ Generates update recommendations
- ✅ Creates JSON report of available updates

#### 2. **[SECURITY] Security Update Check**
- 📋 Placeholder for security advisory checking
- 📋 Basic hardcoded credential detection
- 📋 Unsafe network operation detection

### **Artifacts Generated**
- `maintenance-report.md`: Human-readable summary
- `module-updates.json`: Machine-readable update data

---

## 🎯 Best Practices

### **For Developers**

#### **Before Committing**
```powershell
# Always run syntax validation locally
.\scripts\Validate-PowerShellSyntax.ps1 -Path .\rules\core
.\scripts\Validate-PowerShellSyntax.ps1 -Path .\scripts

# Run unit tests
.\scripts\Run-Tests.ps1
```

#### **STIG Rule Development**
- ✅ Follow naming convention: `WN11-XX-000000.ps1`
- ✅ Implement `Test-[RuleName]` function
- ✅ Include all required return properties
- ✅ Add proper error handling with `try/catch`
- ✅ No Unicode characters (emojis, special symbols)

#### **PowerShell Standards**
- ✅ Use ASCII prefixes: `[STIG]`, `[SUCCESS]`, `[ERROR]`, etc.
- ✅ Include comment-based help for functions
- ✅ Proper parameter validation
- ✅ Consistent error handling patterns

### **For Repository Management**

#### **Branch Protection**
Recommended settings for `main` branch:
- ✅ Require status checks: `validate-syntax`, `run-tests`, `validate-rules`
- ✅ Require up-to-date branches
- ✅ Restrict pushes to specific people/teams

#### **Required Reviews**
- ✅ At least 1 reviewer for PRs
- ✅ Dismiss stale reviews when new commits pushed
- ✅ Require review from code owners

---

## 🚨 Troubleshooting

### **Common CI Failures**

#### **PowerShell Syntax Errors**
```
[ERROR] PowerShell syntax validation failed
```
**Solution**: Run `.\scripts\Validate-PowerShellSyntax.ps1` locally and fix Unicode issues

#### **STIG Rule Validation Failures**
```
[ERROR] Missing required property 'RuleID'
```
**Solution**: Ensure STIG rule functions return all required properties

#### **Test Failures**
```
[ERROR] X tests failed
```
**Solution**: Run `.\scripts\Run-Tests.ps1` locally and fix failing tests

#### **Security Scan Warnings**
```
[WARNING] Potentially dangerous pattern found
```
**Solution**: Review flagged code patterns and implement safer alternatives

### **Workflow Debugging**

#### **View Workflow Runs**
1. Navigate to repository → Actions tab
2. Select specific workflow run
3. Expand job steps for detailed logs

#### **Manual Workflow Triggering**
1. Actions tab → Select workflow
2. Click "Run workflow" button
3. Choose branch and parameters

#### **Download Artifacts**
1. Completed workflow run → Artifacts section
2. Download test results, reports, or packages

---

## 📈 Metrics and Reporting

### **Key Performance Indicators**

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| **Test Pass Rate** | >95% | 90-95% | <90% |
| **Code Coverage** | >80% | 70-80% | <70% |
| **Documentation Coverage** | >70% | 50-70% | <50% |
| **Quality Score** | >80 | 60-80 | <60 |
| **Security Issues** | 0 High-Risk | 1-2 High-Risk | >2 High-Risk |

### **Trend Analysis**
Monitor these metrics over time:
- 📈 Number of STIG rules implemented
- 📈 Test coverage percentage
- 📈 Code quality scores
- 📉 Security vulnerabilities found
- 📉 Build failure rate

---

## 🔮 Future Enhancements

### **Planned Features**
- **PowerShell Gallery Publishing**: Automatic module publishing on releases
- **Multi-OS Testing**: Test on different Windows versions
- **Performance Benchmarking**: Track assessment execution times
- **Security Scanning Integration**: GitHub Security Advisories, Dependabot
- **Automated Documentation**: Generate API docs from comment-based help

### **Integration Opportunities**
- **SIEM Integration**: Export findings to security tools
- **Compliance Dashboards**: Real-time compliance monitoring
- **Enterprise Deployment**: Multi-system assessment automation
- **Custom Rule Development**: Framework for organizational rules

---

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/writing-portable-modules)
- [Pester Testing Framework](https://pester.dev/)
- [DISA STIG Requirements](https://public.cyber.mil/stigs/)

---

*This documentation is maintained alongside the CI/CD workflows. Last updated: August 2025*

# 🧪 Testing vs 🔍 Assessment: What's the Difference?

This Windows 11 STIG Assessment Tool has **two completely separate testing systems**. Understanding the difference is crucial!

## 📋 **Quick Summary**

| **Development Tests (Pester)** | **STIG Compliance Assessment** |
|---|---|
| 🧪 **Mock scenarios for code validation** | 🔍 **Real security compliance checking** |
| 🛠️ Used during development | ⚖️ Used during security audits |
| 📝 Tests if the code works | 🔒 Tests if Windows is secure |
| 🚀 Run with `.\scripts\Run-Tests.ps1` | 📊 Run with `.\scripts\Start-STIGAssessment.ps1` |

---

## 🧪 **Development Tests (Pester Framework)**

### **Purpose**
- Validate that the PowerShell code functions correctly
- Test edge cases and error handling
- Ensure code quality during development

### **When to Use**
- During development
- Before committing code changes  
- When debugging rule logic
- For continuous integration

### **What It Tests**
- Mock Windows settings
- Simulated registry values
- Error handling scenarios
- Function parameter validation

### **How to Run**
```powershell
# Run all development tests
.\scripts\Run-Tests.ps1

# Run specific test categories
.\scripts\Run-Tests.ps1 -TestType Unit
.\scripts\Run-Tests.ps1 -TestType Integration

# Run with code coverage
.\scripts\Run-Tests.ps1 -GenerateCoverage
```

### **Example Test Files**
- `tests\Rules.Tests.ps1` - Unit tests for STIG rule functions
- `tests\Scripts.Tests.ps1` - Tests for CLI scripts
- `tests\Integration.Tests.ps1` - End-to-end workflow tests

---

## 🔍 **STIG Compliance Assessment**

### **Purpose**
- Check actual Windows 11 security compliance
- Generate compliance reports for audits
- Identify security misconfigurations
- Provide remediation guidance

### **When to Use**
- During security assessments
- For compliance audits
- When hardening Windows systems
- For regular security monitoring

### **What It Tests**
- Real Windows security settings
- Actual registry values
- Live system configurations
- Current feature states

### **How to Run**
```powershell
# Run full STIG assessment
.\scripts\Start-STIGAssessment.ps1

# Run with admin privileges (recommended)
.\scripts\Start-STIGAssessment.ps1 -RequestAdmin

# Filter by rule category
.\scripts\Start-STIGAssessment.ps1 -RuleFilter "CAT I"

# Generate specific report format
.\scripts\Start-STIGAssessment.ps1 -Format HTML
```

### **Example Rule Files**
- `rules\core\WN11-SO-000001.ps1` - Disable SMBv1 Protocol
- `rules\core\WN11-SO-000005.ps1` - Disable PowerShell 2.0
- `rules\core\WN11-SO-000010.ps1` - Disable Simple TCP/IP Services

---

## 🎯 **Key Differences**

### **Data Sources**
| Development Tests | STIG Assessment |
|---|---|
| Mock objects and test data | Real Windows system settings |
| Predefined scenarios | Current system state |
| Simulated conditions | Live registry and features |

### **Results**
| Development Tests | STIG Assessment |
|---|---|
| Pass/Fail for code logic | Compliant/Non-Compliant for security |
| Code coverage metrics | Compliance percentage |
| Development feedback | Audit-ready reports |

### **Environment**
| Development Tests | STIG Assessment |
|---|---|
| Any development machine | Target Windows 11 systems |
| No admin rights needed | Admin rights recommended |
| Isolated test environment | Production/test environments |

---

## ⚠️ **Important Notes**

1. **Never confuse the two!**
   - Development tests validate code
   - STIG assessments validate security

2. **Admin privileges matter**
   - Development tests work without admin rights
   - STIG assessments need admin rights for accurate results

3. **Different output formats**
   - Development tests show pass/fail results
   - STIG assessments show compliance status

4. **Separate file locations**
   - Tests: `tests/*.Tests.ps1`
   - Rules: `rules/core/*.ps1`

---

## 🚀 **Quick Start Examples**

### **For Developers** (Testing Code)
```powershell
# Check if my new rule code works correctly
.\scripts\Run-Tests.ps1 -TestType Unit

# Test with code coverage
.\scripts\Run-Tests.ps1 -GenerateCoverage -GenerateReport
```

### **For Security Teams** (Checking Compliance)
```powershell
# Check Windows 11 security compliance
.\scripts\Start-STIGAssessment.ps1 -RequestAdmin

# Generate HTML report for audit
.\scripts\Start-STIGAssessment.ps1 -Format HTML -RequestAdmin
```

---

## 📖 **More Information**

- **Pester Documentation**: [pester.dev](https://pester.dev)
- **DISA STIG Guidelines**: [public.cyber.mil](https://public.cyber.mil)
- **Project Setup**: See `SETUP_GUIDE.md`

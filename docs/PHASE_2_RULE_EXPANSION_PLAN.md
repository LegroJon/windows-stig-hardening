# Phase 2: Rule Expansion Plan
## Windows 11 STIG Assessment Tool - Enterprise Rule Coverage

**Duration**: 4 weeks  
**Goal**: Expand from 12 to 57 STIG rules (375% increase)  
**Success Criteria**: 70%+ compliance rate, 5 major STIG categories covered

---

## 🎯 **Strategic Rule Implementation**

### **Current State Analysis**
- **Implemented**: 12 rules (SO + AU categories)
- **Target**: 57 rules across 5 categories
- **Gap**: 45 new rules needed
- **Priority**: High-impact security controls first

### **Category Implementation Priority**

| Category | Rules | Impact | Implementation Order |
|----------|-------|--------|-------------------|
| **AC (Access Control)** | 15 | Critical | Week 1 |
| **SC (System Communications)** | 12 | High | Week 2 |
| **CM (Configuration Management)** | 10 | High | Week 3 |
| **IA (Identification & Authentication)** | 8 | Medium | Week 4 |

---

## 🎯 **Week 3-4: Access Control (AC) Rules**

### **AC Category: Critical Security Controls**
**Target**: 15 AC rules covering user access, permissions, and account management

#### **High-Priority AC Rules**
```powershell
# Week 3 Implementation
WN11-AC-000001  # User Account Control Configuration
WN11-AC-000002  # Admin Account Policies  
WN11-AC-000003  # Guest Account Management
WN11-AC-000004  # Password Policy Requirements
WN11-AC-000005  # Account Lockout Policies
WN11-AC-000006  # Login Rights Assignment
WN11-AC-000007  # Privilege Escalation Controls
WN11-AC-000008  # Service Account Management

# Week 4 Implementation  
WN11-AC-000009  # Remote Desktop Access Controls
WN11-AC-000010  # Network Access Restrictions
WN11-AC-000011  # File System Permissions
WN11-AC-000012  # Registry Access Controls
WN11-AC-000013  # Application Execution Policies
WN11-AC-000014  # Removable Media Controls
WN11-AC-000015  # Shared Resource Permissions
```

#### **Implementation Template**
```powershell
<#
.SYNOPSIS
    User Account Control Configuration

.DESCRIPTION
    STIG Rule: WN11-AC-000001
    Category: CAT I
    
    Validates User Account Control (UAC) settings for proper security configuration

.NOTES
    Generated from DISA STIG documentation
    Rule ID: WN11-AC-000001
    Severity: CAT I
    Required Privileges: SeSecurityPrivilege
#>

function Test-WN11AC000001 {
    [CmdletBinding()]
    param()
    
    try {
        # Check UAC registry settings
        $uacSettings = @{
            ConsentPromptBehaviorAdmin = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue
            EnableLUA = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
            PromptOnSecureDesktop = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -ErrorAction SilentlyContinue
        }
        
        $compliant = $true
        $issues = @()
        
        # Validate UAC is enabled
        if ($uacSettings.EnableLUA.EnableLUA -ne 1) {
            $compliant = $false
            $issues += "UAC is disabled"
        }
        
        # Validate admin consent prompt
        if ($uacSettings.ConsentPromptBehaviorAdmin.ConsentPromptBehaviorAdmin -ne 2) {
            $compliant = $false
            $issues += "Admin consent prompt not configured for secure desktop"
        }
        
        # Validate secure desktop
        if ($uacSettings.PromptOnSecureDesktop.PromptOnSecureDesktop -ne 1) {
            $compliant = $false
            $issues += "UAC prompts not displayed on secure desktop"
        }
        
        return @{
            RuleID   = "WN11-AC-000001"
            Status   = if ($compliant) { "Compliant" } else { "Non-Compliant" }
            Evidence = $uacSettings
            Issues   = $issues
            FixText  = @"
Enable User Account Control:
1. Open Group Policy Editor (gpedit.msc)
2. Navigate to Computer Configuration > Windows Settings > Security Settings > Local Policies > Security Options
3. Set "User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode" to "Prompt for consent on the secure desktop"
4. Set "User Account Control: Run all administrators in Admin Approval Mode" to "Enabled"
"@
        }
    }
    catch {
        return @{
            RuleID   = "WN11-AC-000001"
            Status   = "Error"
            Evidence = $null
            Issues   = @("Failed to check UAC settings: $($_.Exception.Message)")
            FixText  = "Ensure administrative privileges and try again"
        }
    }
}
```

---

## 🎯 **Week 5: System Communications (SC) Rules**

### **SC Category: Network & Communication Security**
**Target**: 12 SC rules covering network protocols, encryption, and communication security

#### **SC Rules Implementation**
```powershell
WN11-SC-000001  # Network Protocol Security
WN11-SC-000002  # SSL/TLS Configuration
WN11-SC-000003  # IPSec Implementation
WN11-SC-000004  # Wireless Network Security
WN11-SC-000005  # Remote Access Controls
WN11-SC-000006  # Network Shares Security
WN11-SC-000007  # Firewall Configuration
WN11-SC-000008  # Port Security Management
WN11-SC-000009  # VPN Configuration
WN11-SC-000010  # Network Encryption
WN11-SC-000011  # Communication Protocols
WN11-SC-000012  # Data Transmission Security
```

---

## 🎯 **Week 6: Configuration Management (CM) Rules**

### **CM Category: System Configuration Controls**
**Target**: 10 CM rules covering system configuration, change management, and baseline controls

#### **CM Rules Implementation**
```powershell
WN11-CM-000001  # System Configuration Baseline
WN11-CM-000002  # Software Installation Controls
WN11-CM-000003  # System Update Management
WN11-CM-000004  # Registry Configuration
WN11-CM-000005  # Service Configuration
WN11-CM-000006  # Driver Installation Controls
WN11-CM-000007  # System File Integrity
WN11-CM-000008  # Configuration Change Tracking
WN11-CM-000009  # Baseline Compliance Monitoring
WN11-CM-000010  # System Hardening Configuration
```

---

## 🔧 **Automated Rule Generation**

### **Rule Generation Script**
```powershell
# scripts/Generate-STIGRules.ps1
function New-STIGRule {
    param(
        [string]$RuleID,
        [string]$Category,
        [string]$Title,
        [string]$Severity,
        [string]$Description
    )
    
    $template = Get-Content ".\templates\rule-template.ps1" -Raw
    $template = $template -replace "__RULEID__", $RuleID
    $template = $template -replace "__CATEGORY__", $Category
    $template = $template -replace "__TITLE__", $Title
    $template = $template -replace "__SEVERITY__", $Severity
    $template = $template -replace "__DESCRIPTION__", $Description
    
    $outputPath = ".\rules\core\$RuleID.ps1"
    $template | Set-Content $outputPath
    
    Write-Host "[SUCCESS] Generated rule: $RuleID" -ForegroundColor Green
}

# Batch generate AC rules
$acRules = @(
    @{ID="WN11-AC-000001"; Title="User Account Control"; Severity="CAT I"}
    @{ID="WN11-AC-000002"; Title="Admin Account Policies"; Severity="CAT I"}
    # ... additional rules
)

foreach ($rule in $acRules) {
    New-STIGRule @rule -Category "Access Control"
}
```

### **Rule Validation Pipeline**
```powershell
# scripts/Validate-NewRules.ps1
function Test-RuleImplementation {
    param([string]$RulePath)
    
    $checks = @{
        SyntaxValid = Test-PowerShellSyntax -Path $RulePath
        NamingCorrect = Test-FunctionNaming -Path $RulePath
        DocumentationComplete = Test-RuleDocumentation -Path $RulePath
        ErrorHandling = Test-ErrorHandling -Path $RulePath
    }
    
    $allPassed = ($checks.Values | Where-Object {$_ -eq $false}).Count -eq 0
    
    return @{
        RulePath = $RulePath
        Checks = $checks
        Valid = $allPassed
    }
}
```

---

## 📊 **Implementation Metrics & Targets**

### **Weekly Targets**
| Week | Rules Added | Cumulative | Category Focus |
|------|-------------|------------|----------------|
| **Week 3** | 8 AC Rules | 20 rules | Access Control |
| **Week 4** | 7 AC Rules | 27 rules | Access Control |
| **Week 5** | 12 SC Rules | 39 rules | System Communications |
| **Week 6** | 10 CM Rules | 49 rules | Configuration Management |

### **Quality Metrics**
- **Rule Success Rate**: 95%+ for new rules
- **Documentation Coverage**: 100% complete metadata
- **Test Coverage**: 80%+ for each new rule
- **Performance**: <30 seconds per rule execution

### **Compliance Projections**
- **Current**: 8.33% compliance (1/12 rules)
- **Week 3**: ~25% compliance (5/20 rules)
- **Week 4**: ~30% compliance (8/27 rules)  
- **Week 5**: ~35% compliance (14/39 rules)
- **Week 6**: ~40% compliance (20/49 rules)

---

## 🔄 **Continuous Integration Updates**

### **Enhanced Testing Pipeline**
```yaml
# .github/workflows/rule-validation.yml
name: New Rule Validation

on:
  push:
    paths: ['rules/core/*.ps1']

jobs:
  validate-rules:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test New Rules
        run: |
          .\scripts\Validate-NewRules.ps1 -ShowDetails
          .\scripts\Test-RuleCoverage.ps1 -MinimumCoverage 80
```

### **Automated Documentation**
```powershell
# scripts/Update-RuleDocumentation.ps1
function Update-RulesMetadata {
    $rules = Get-ChildItem ".\rules\core\*.ps1"
    $metadata = @()
    
    foreach ($rule in $rules) {
        $ruleInfo = Get-RuleMetadata -RulePath $rule.FullName
        $metadata += $ruleInfo
    }
    
    $metadata | ConvertTo-Json -Depth 10 | Set-Content ".\config\rules.json"
}
```

---

## 📅 **Phase 2 Success Criteria**

### **Completion Targets**
- [ ] 45+ new STIG rules implemented
- [ ] 5 major categories covered (SO, AU, AC, SC, CM)
- [ ] 40%+ system compliance rate achieved
- [ ] <5% rule error rate maintained
- [ ] 100% documentation coverage
- [ ] Automated rule generation pipeline

### **Quality Gates**
- [ ] All new rules pass syntax validation
- [ ] Function naming consistency maintained
- [ ] Error handling implemented in all rules
- [ ] Performance benchmarks met
- [ ] Integration tests passing

---

**Next Phase**: Upon completion, proceed to Phase 3 (Enterprise Features)

# 🐛 Debugging Guide for Windows 11 STIG Assessment Tool

This guide explains how to debug and test the STIG Assessment Tool using VS Code's integrated debugging features.

## 🚀 **Quick Start - How to Debug**

### **Method 1: Using VS Code Debug Menu**
1. **Open VS Code** in the project root directory
2. **Press F5** or click **Run and Debug** in the sidebar
3. **Select a debug configuration** from the dropdown:
   - `[STIG] Debug Main Assessment` - Debug the full assessment
   - `[STIG] Debug HTML Report Generation` - Debug report generation
   - `[STIG] Debug Single Rule - WN11-SO-000010` - Debug individual rule

### **Method 2: Using Command Palette**
1. **Press Ctrl+Shift+P** to open Command Palette
2. **Type:** `Debug: Start Debugging`
3. **Select your configuration**

### **Method 3: Using Tasks**
1. **Press Ctrl+Shift+P** to open Command Palette  
2. **Type:** `Tasks: Run Task`
3. **Select a STIG task:**
   - `[STIG] Run Full Assessment`
   - `[STIG] Quick Assessment`
   - `[STIG] Validate PowerShell Syntax`

## 🔧 **Available Debug Configurations**

| Configuration | Purpose | Script | Arguments |
|---------------|---------|--------|-----------|
| **Main Assessment** | Debug full assessment | `Start-STIGAssessment.ps1` | `-WhatIf -Format JSON -Verbose` |
| **HTML Report** | Debug report generation | `Start-STIGAssessment.ps1` | `-WhatIf -Format HTML -Verbose` |
| **Single Rule** | Debug individual rule | `WN11-SO-000010.ps1` | None |
| **Quick Assessment** | Debug quick scan | `Quick-Assessment.ps1` | `-Verbose` |
| **Syntax Validation** | Debug syntax checker | `Validate-PowerShellSyntax.ps1` | `-Path .\rules\core -Verbose` |
| **Test Suite** | Debug unit tests | `Run-Tests.ps1` | `-TestType Unit -Verbose` |
| **Prerequisites** | Debug system checks | `Test-Prerequisites.ps1` | `-Verbose` |
| **Execution Policy** | Debug policy checks | `Test-ExecutionPolicy.ps1` | `-Verbose` |
| **Admin Check** | Debug privilege checks | `Test-Admin.ps1` | `-Verbose` |

## 🎯 **Debugging Workflow**

### **Step 1: Set Breakpoints**
1. **Open the PowerShell script** you want to debug
2. **Click in the left margin** next to line numbers to set breakpoints (red dots)
3. **Breakpoints pause execution** at that line for inspection

### **Step 2: Start Debugging**
1. **Select appropriate debug configuration**
2. **Press F5** to start debugging
3. **Execution will pause** at your breakpoints

### **Step 3: Inspect Variables**
- **Variables panel** shows current variable values
- **Watch panel** lets you monitor specific expressions
- **Call stack** shows function call hierarchy
- **Debug console** allows interactive PowerShell commands

### **Step 4: Control Execution**
| Key | Action | Description |
|-----|--------|-------------|
| **F5** | Continue | Resume execution |
| **F10** | Step Over | Execute current line, don't enter functions |
| **F11** | Step Into | Enter function calls |
| **Shift+F11** | Step Out | Exit current function |
| **Ctrl+Shift+F5** | Restart | Restart debugging session |
| **Shift+F5** | Stop | Stop debugging |

## 🧪 **Common Debugging Scenarios**

### **Debugging Assessment Execution**
```powershell
# Set breakpoint at line where assessment starts
# Configuration: [STIG] Debug Main Assessment
# Watch variables: $Config, $Rules, $Results
```

### **Debugging HTML Report Generation**
```powershell
# Set breakpoint in Generate-HTMLReport function
# Configuration: [STIG] Debug HTML Report Generation  
# Watch variables: $Data, $templateDir, $html
```

### **Debugging Individual STIG Rules**
```powershell
# Set breakpoint in Test-WN11SO000010 function
# Configuration: [STIG] Debug Single Rule
# Watch variables: $feature, $status, $evidence
```

### **Debugging Template Processing**
```powershell
# Set breakpoint in template loading code
# Watch variables: $templateDir, $summaryTemplate, $html
# Check template file existence and content replacement
```

## 🔍 **Troubleshooting Debug Issues**

### **PowerShell Extension Required**
- **Install:** PowerShell extension by Microsoft
- **Verify:** Check Extensions panel for "PowerShell"

### **Execution Policy Issues**
- **Debug configs use:** `-ExecutionPolicy Bypass` automatically
- **Manual override:** Set execution policy before debugging

### **Script Not Found Errors**
- **Check paths:** Ensure all script paths in launch.json are correct
- **Working directory:** Confirm `cwd` is set to `${workspaceFolder}`

### **Breakpoints Not Hit**
- **PowerShell version:** Use PowerShell 5.1+ or PowerShell 7+
- **Script loading:** Ensure script is being executed, not just imported
- **Syntax errors:** Fix any syntax errors that prevent execution

## 📊 **Debug Output Interpretation**

### **Verbose Output**
- `[INFO]` messages show normal operation
- `[ERROR]` messages indicate failures
- `[WARN]` messages show potential issues
- `[DEBUG]` messages provide detailed execution info

### **Assessment Results**
```powershell
# Example debug output:
Assessment completed: 1 compliant, 4 non-compliant, 7 errors
HTML report exported: .\reports\STIG-Assessment-20250729-212943.html
```

### **Template Processing**
```powershell
# Debug template loading:
Using external HTML templates from: .\templates
Successfully loaded external HTML templates
HTML report generated using external templates
```

## 🛠 **Advanced Debugging Techniques**

### **Conditional Breakpoints**
1. **Right-click breakpoint** → **Edit Breakpoint**
2. **Add condition:** `$RuleID -eq "WN11-SO-000010"`
3. **Breakpoint only triggers** when condition is true

### **Log Point (Tracepoint)**
1. **Right-click in margin** → **Add Logpoint**
2. **Enter message:** `Rule {$RuleID} status: {$Status}`
3. **Logs message** without stopping execution

### **Debug Console Commands**
```powershell
# While debugging, use debug console:
$Config.assessment.name           # Check config values
$Rules.Count                      # Check rule count
Get-Variable | Format-Table       # List all variables
```

## 🎨 **Debugging HTML Templates**

### **Template Variable Inspection**
```powershell
# Set breakpoint after template loading
# Inspect template content and variable replacement
$summaryHtml = $summaryTemplate   # Before replacement
$summaryHtml -replace "{{ASSESSMENT_NAME}}", $Data.Assessment.Name  # After
```

### **Template File Validation**
```powershell
# Debug template file existence
Test-Path $templateDir                    # Check directory
Get-ChildItem $templateDir -Filter "*.html"  # List template files
```

## 📋 **Debug Checklist**

Before debugging, ensure:
- ✅ **PowerShell extension** installed in VS Code
- ✅ **Working directory** set correctly in debug config
- ✅ **Execution policy** allows script execution
- ✅ **Administrative privileges** if testing system settings
- ✅ **Template files** exist if debugging HTML generation
- ✅ **Configuration files** are valid JSON

## 🔗 **Related Resources**

- **VS Code PowerShell Debugging:** [Official Documentation](https://code.visualstudio.com/docs/languages/powershell)
- **PowerShell Debugging:** [Microsoft PowerShell Docs](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/vscode/using-vscode)
- **Project Documentation:** `docs/` directory
- **Configuration Files:** `config/settings.json`

---

**Last Updated**: July 29, 2025  
**VS Code Version**: 1.80+  
**PowerShell Extension**: v2023.8.0+

# 📄 HTML Templates Directory

This directory contains externalized HTML templates for the Windows 11 STIG Assessment Tool's report generation.

## 🎯 **Purpose**

These templates separate presentation (HTML/CSS) from logic (PowerShell), making the reports easier to customize and maintain.

## 📁 **Template Files**

| File | Purpose | Size | Description |
|------|---------|------|-------------|
| `report-header.html` | 7.8KB | CSS styles and page structure |
| `executive-summary.html` | 3.9KB | Dashboard summary with statistics |
| `non-compliant-section.html` | 356B | Container for non-compliant rules |
| `rule-compliant.html` | 423B | Template for compliant rule items |
| `rule-non-compliant.html` | 560B | Template for non-compliant rule items |
| `rule-error.html` | 419B | Template for error rule items |
| `report-footer.html` | 893B | JavaScript functionality and footer |

**Total**: 14.4KB of externalized templates

## 🔧 **Template Variables**

Templates use `{{VARIABLE_NAME}}` placeholders that are replaced by PowerShell at runtime:

### **Assessment Information**
- `{{ASSESSMENT_NAME}}` - Assessment tool name
- `{{ASSESSMENT_VERSION}}` - Tool version
- `{{COMPUTER_NAME}}` - Target computer name
- `{{USER_NAME}}` - Current user
- `{{IS_ADMINISTRATOR}}` - Admin privileges status
- `{{TIMESTAMP}}` - Report generation time
- `{{DURATION}}` - Assessment duration in seconds

### **Risk Assessment**
- `{{RISK_LEVEL}}` - LOW, MODERATE, HIGH, CRITICAL
- `{{RISK_COLOR}}` - CSS color for risk level
- `{{RISK_BG}}` - CSS background color for risk level

### **Statistics**
- `{{COMPLIANCE_PERCENTAGE}}` - Overall compliance percentage
- `{{COMPLIANT_COUNT}}` - Number of compliant rules
- `{{NON_COMPLIANT_COUNT}}` - Number of non-compliant rules
- `{{ERROR_COUNT}}` - Number of rules with errors

### **Rule-Specific**
- `{{RULE_ID}}` - Individual rule identifier (e.g., WN11-SO-000010)
- `{{EVIDENCE}}` - Rule evidence/findings
- `{{FIX_TEXT}}` - Remediation instructions
- `{{ERROR_MESSAGE}}` - Error details for failed rules

## 🚨 **CSS Linting Warnings**

**EXPECTED BEHAVIOR**: VS Code will show CSS linting errors for template placeholders like `{{RISK_COLOR}}`.

### **Why This Happens**
- The CSS linter sees `{{VARIABLE_NAME}}` and thinks it's invalid CSS
- These are template placeholders, not actual CSS values
- At runtime, PowerShell replaces them with valid values

### **Example Transformation**
```html
<!-- TEMPLATE (shows CSS errors) -->
<div style="background: {{RISK_BG}}; color: {{RISK_COLOR}};">

<!-- RUNTIME (valid CSS) -->
<div style="background: #fadbd8; color: #e74c3c;">
```

### **How to Handle**
1. **✅ Ignore the warnings** - They're expected for template files
2. **✅ VS Code settings** - Workspace settings disable CSS validation for templates
3. **✅ Focus on functionality** - Templates work correctly despite warnings

## 🔄 **Template Processing Flow**

1. **PowerShell script** detects templates in this directory
2. **Loads template files** using `Get-Content`
3. **Replaces placeholders** using PowerShell's `-replace` operator
4. **Generates final HTML** with valid CSS and data
5. **Saves report** to `reports/` directory

### **Fallback Mechanism**
If templates are missing or corrupted:
- PowerShell automatically falls back to embedded HTML
- Assessment continues without interruption
- Warning logged but tool remains functional

## 🎨 **Customization Guide**

### **Modifying Templates**
1. Edit template files directly in this directory
2. Maintain `{{VARIABLE_NAME}}` placeholders
3. Test changes by running assessment with HTML output
4. Templates are loaded fresh each time (no caching)

### **Adding New Variables**
1. Add placeholder to template: `{{NEW_VARIABLE}}`
2. Update PowerShell script to replace the placeholder
3. Document the new variable in this README

### **Styling Changes**
- CSS is in `report-header.html`
- Modify colors, fonts, layout without touching PowerShell
- Use browser developer tools to test changes
- Responsive design supported for mobile viewing

## 🧪 **Testing Templates**

### **Generate Test Report**
```powershell
# Run assessment with HTML output
.\scripts\Start-STIGAssessment.ps1 -Format HTML

# Check generated report
Get-Item .\reports\STIG-Assessment-*.html | Sort-Object LastWriteTime | Select-Object -Last 1
```

### **Validate Template Loading**
Look for these log messages:
```
[INFO] Using external HTML templates from: .\templates
[INFO] HTML report generated using external templates
```

### **Fallback Testing**
Temporarily rename templates directory to test fallback:
```powershell
Rename-Item templates templates-backup
# Run assessment - should use embedded HTML
Rename-Item templates-backup templates
```

## 🔒 **Security Considerations**

- Templates are **read-only** during report generation
- No user input is directly inserted into templates
- All variable replacement uses safe PowerShell string operations
- Generated HTML is safe for enterprise environments

## 📚 **Additional Resources**

- **PowerShell Script**: `scripts\Start-STIGAssessment.ps1` (template processing logic)
- **Generated Reports**: `reports\` directory (example outputs)
- **Configuration**: `config\settings.json` (template settings)
- **Documentation**: `docs\` directory (additional guides)

---

**Last Updated**: July 29, 2025  
**Template System Version**: 1.0  
**Compatibility**: Windows 11 STIG Assessment Tool v1.0+

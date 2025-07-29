# 📚 Windows 11 STIG Assessment Tool - Documentation

Welcome to the complete documentation for the Windows 11 STIG Assessment Tool. This folder contains all guides, references, and technical documentation.

## 🚀 **Quick Start**

| Document | Purpose | Target Audience |
|----------|---------|-----------------|
| [SETUP_GUIDE.md](SETUP_GUIDE.md) | Complete installation and setup instructions | **Everyone** |
| [TESTING_EXPLAINED.md](TESTING_EXPLAINED.md) | Difference between development tests vs compliance assessment | **Everyone** |

## 📖 **Main Documentation**

### **🛠️ For Users & Security Teams**
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Installation, prerequisites, and initial configuration
- **[TESTING_EXPLAINED.md](TESTING_EXPLAINED.md)** - Understanding development tests vs STIG compliance assessment

### **⚡ For Developers**
- **[DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md)** - Technical roadmap, architecture, and implementation phases
- **[STIG_RESOURCES.md](STIG_RESOURCES.md)** - DISA STIG references, compliance standards, and official documentation

---

## 🎯 **Documentation by Use Case**

### **"I want to use this tool"** → Start here:
1. [SETUP_GUIDE.md](SETUP_GUIDE.md) - Get everything installed
2. [TESTING_EXPLAINED.md](TESTING_EXPLAINED.md) - Understand what the tool does

### **"I want to develop/contribute"** → Start here:
1. [SETUP_GUIDE.md](SETUP_GUIDE.md) - Development environment setup
2. [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) - Technical architecture and roadmap
3. [STIG_RESOURCES.md](STIG_RESOURCES.md) - Official STIG references

### **"I need STIG compliance info"** → Start here:
1. [STIG_RESOURCES.md](STIG_RESOURCES.md) - Official DISA resources and documentation
2. [TESTING_EXPLAINED.md](TESTING_EXPLAINED.md) - Understanding compliance vs development testing

---

## 🔍 **Quick Reference**

### **Essential Commands**
```powershell
# Run STIG compliance assessment
.\scripts\Start-STIGAssessment.ps1 -RequestAdmin

# Run development tests
.\scripts\Run-Tests.ps1

# Install prerequisites
.\scripts\Install-TestingTools.ps1
```

### **Key Concepts**
- **STIG Assessment**: Tests real Windows security settings for compliance
- **Development Tests**: Tests code logic using Pester framework
- **Rule Engine**: Modular system for adding/executing STIG checks
- **Admin Privileges**: Required for accurate compliance assessment

---

## 📂 **Related Documentation**

### **In Other Folders**
- `../README.md` - Project overview and quick start
- `../tests/README.md` - Testing framework details
- `../scripts/README.md` - CLI tools documentation
- `../rules/core/README.md` - STIG rule implementation guide

### **GitHub Integration**
- `../.github/copilot-instructions.md` - AI coding assistant guidelines
- `../.vscode/templates/` - Development templates and snippets

---

## 🆘 **Getting Help**

### **Common Issues**
1. **Execution Policy Errors** → See [SETUP_GUIDE.md](SETUP_GUIDE.md#troubleshooting)
2. **Admin Rights Required** → See [TESTING_EXPLAINED.md](TESTING_EXPLAINED.md#admin-privileges)
3. **Pester vs Assessment Confusion** → See [TESTING_EXPLAINED.md](TESTING_EXPLAINED.md)

### **Development Questions**
- Architecture details → [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md)
- STIG references → [STIG_RESOURCES.md](STIG_RESOURCES.md)
- Contributing guidelines → [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md#contributing)

---

## 📋 **Document Status**

| Document | Status | Last Updated | Notes |
|----------|--------|--------------|-------|
| SETUP_GUIDE.md | ✅ Complete | Current | Installation & prerequisites |
| TESTING_EXPLAINED.md | ✅ Complete | Current | Pester vs STIG assessment |
| DEVELOPMENT_PLAN.md | 🔄 Active | Current | Technical roadmap |
| STIG_RESOURCES.md | ✅ Complete | Current | Official DISA references |

---

*For the latest updates and issues, check the [project repository](https://github.com/LegroJon/windows-stig-hardening).*

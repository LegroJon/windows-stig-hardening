# Unit Tests

This folder contains Pester tests for validating rule logic and system functionality.

## Test Structure
- **Rules.Tests.ps1** - Tests for core STIG rules
- **CustomRules.Tests.ps1** - Tests for custom rules
- **Scripts.Tests.ps1** - Tests for CLI scripts
- **Integration.Tests.ps1** - End-to-end integration tests

## Running Tests
```powershell
# Run all tests
Invoke-Pester

# Run specific test file
Invoke-Pester -Path ".\Rules.Tests.ps1"

# Run with coverage
Invoke-Pester -CodeCoverage "*.ps1"
```

## Test Requirements
- Pester v5.x or higher
- Administrative privileges for some tests
- Mock objects for system calls

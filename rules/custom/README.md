# Custom Rule Checks

This folder contains user-defined plugin rules that extend the official STIG assessments.

## Purpose
- Custom organizational security requirements
- Additional hardening checks beyond DISA STIGs
- Environment-specific compliance rules

## Naming Convention
- Use descriptive names: `Custom-DisableUnnecessaryServices.ps1`
- Function names should start with `Test-Custom-`

## Example Structure
```
Custom-DisableUnnecessaryServices.ps1
Custom-NetworkSecuritySettings.ps1
Custom-ApplicationWhitelisting.ps1
```

All custom rules must follow the same return format as core STIG rules.

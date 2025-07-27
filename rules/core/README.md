# Official STIG Rule Checks

This folder contains the official DISA STIG rule implementations for Windows 11.

## Naming Convention
- Files should be named using the STIG rule ID: `WN11-SO-000001.ps1`
- Function names should start with `Test-` followed by a descriptive name

## Example Structure
```
WN11-SO-000001.ps1 - Disable SMBv1 Protocol
WN11-SO-000002.ps1 - Configure Password Policy
WN11-AU-000001.ps1 - Audit Policy Settings
```

Each rule script must implement the standard return format as defined in the project guidelines.

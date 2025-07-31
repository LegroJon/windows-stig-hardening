# MCP Integration with NIST NCP Repository
## Windows 11 STIG Assessment Tool - Enterprise Integration Guide

### Overview
The Model Context Protocol (MCP) integration transforms the standalone STIG assessment tool into an enterprise-ready cybersecurity compliance platform. By integrating with the NIST National Cybersecurity Portal (NCP) Repository, the tool provides authoritative, up-to-date cybersecurity standards and real-time compliance monitoring.

### What is MCP?
Model Context Protocol (MCP) is a standardized protocol for connecting AI applications with external data sources and tools. In this project, MCP enables:

- **Real-time NIST Standards**: Direct integration with https://ncp.nist.gov/repository
- **Enterprise Connectivity**: SIEM, GRC, and compliance platform integration  
- **Automated Reporting**: Scheduled compliance reports with NIST mappings
- **Organization Baselines**: Custom compliance profiles based on NIST frameworks

### NIST NCP Repository Integration
The NIST National Cybersecurity Portal provides authoritative cybersecurity frameworks and standards:

- **NIST SP 800-53**: Security and Privacy Controls for Federal Information Systems
- **NIST Cybersecurity Framework (CSF)**: Industry-standard cybersecurity framework
- **NIST SP 800-171**: Protecting Controlled Unclassified Information (CUI)
- **NIST Privacy Framework**: Privacy risk management framework

### Configuration Files

#### 1. Main Settings (`config/settings.json`)
Enhanced with MCP and NIST integration sections:

```json
{
    "mcp_integration": {
        "enabled": false,
        "server_url": "localhost:8080",
        "timeout_seconds": 30,
        "secure_mode": true
    },
    "nist_ncp_integration": {
        "enabled": false,
        "repository_url": "https://ncp.nist.gov/repository",
        "api_endpoint": "https://ncp.nist.gov/repository/api/v1",
        "framework_mappings": {
            "stig": "NIST-800-53",
            "cis": "NIST-CSF"
        }
    }
}
```

#### 2. MCP Server Configuration (`config/mcp-server.json`)
Defines MCP server settings, NIST endpoints, and enterprise integrations.

#### 3. NIST Mappings (`config/nist-mappings.json`)
Maps STIG rules to NIST framework controls for compliance reporting.

### Key Features

#### 1. **NIST Standards Integration**
```powershell
# Test NIST NCP Repository connectivity
.\scripts\MCP-NISTIntegration.ps1 -TestConnection

# Update NIST frameworks cache
.\scripts\MCP-NISTIntegration.ps1 -UpdateFrameworks

# Enable NIST integration
.\scripts\MCP-NISTIntegration.ps1 -EnableNISTIntegration
```

#### 2. **Enterprise Reporting**
- **NIST-Compliant Reports**: Reports include NIST control mappings
- **Multiple Formats**: JSON, PDF, Excel with NIST branding
- **Automated Distribution**: Scheduled reports to compliance teams
- **Real-time Updates**: Webhook notifications for critical findings

#### 3. **SIEM Integration**
Supported platforms:
- **Splunk**: JSON events with NIST control context
- **QRadar**: Compliance events with risk scoring
- **Microsoft Sentinel**: Azure Log Analytics integration

#### 4. **GRC Platform Connectivity**
- **ServiceNow GRC**: Automated compliance record creation
- **RSA Archer**: Risk assessment integration
- **MetricStream**: Compliance workflow automation

### Getting Started

#### Step 1: Enable MCP Integration
```powershell
# Enable MCP integration
.\scripts\MCP-NISTIntegration.ps1 -EnableMCP

# Enable NIST integration  
.\scripts\MCP-NISTIntegration.ps1 -EnableNISTIntegration
```

#### Step 2: Test Connectivity
```powershell
# Test all connections
.\scripts\MCP-NISTIntegration.ps1 -TestConnection
```

#### Step 3: Update NIST Frameworks
```powershell
# Cache latest NIST standards
.\scripts\MCP-NISTIntegration.ps1 -UpdateFrameworks
```

#### Step 4: Run Assessment with NIST Mapping
```powershell
# Run assessment with NIST compliance reporting
.\scripts\Start-STIGAssessment.ps1 -EnableNISTMapping -OutputFormat "nist-json"
```

### MCP Server Installation (Optional)
For full enterprise features, install the MCP server:

1. **Download MCP Server**: Install from MCP repository
2. **Configure**: Edit `config/mcp-server.json`
3. **Start Server**: Use auto-start or manual startup
4. **Verify**: Test connectivity with assessment tool

### Enterprise Integration Examples

#### SIEM Integration
```powershell
# Send compliance events to Splunk
$results = .\scripts\Start-STIGAssessment.ps1
Send-ComplianceToSIEM -Results $results -Platform "Splunk"
```

#### GRC Integration
```powershell
# Create compliance records in ServiceNow
$assessment = Start-STIGAssessment -NISTMapping
Create-GRCRecord -Assessment $assessment -Platform "ServiceNow"
```

#### Automated Reporting
```powershell
# Schedule daily NIST compliance reports
Register-ScheduledTask -TaskName "NIST-Compliance-Report" -Trigger (New-ScheduledTaskTrigger -Daily -At "06:00")
```

### Benefits of NIST NCP Integration

#### 1. **Authoritative Standards**
- Direct access to official NIST frameworks
- Real-time updates from authoritative source
- Eliminates manual framework maintenance

#### 2. **Enhanced Compliance**
- NIST control mappings for all STIG rules
- Framework-specific compliance reporting
- Multi-framework compliance assessment

#### 3. **Enterprise Readiness**
- Integration with enterprise security platforms
- Automated compliance workflows
- Standardized reporting formats

#### 4. **Risk Management**
- NIST-based risk scoring
- Framework-aligned remediation guidance
- Compliance gap analysis

### Troubleshooting

#### Common Issues
1. **NIST API Connectivity**: Check internet access to https://ncp.nist.gov
2. **MCP Server**: Verify server is running on correct port
3. **Enterprise Integration**: Check authentication credentials
4. **Cache Issues**: Clear NIST framework cache if outdated

#### Debug Commands
```powershell
# Test NIST connectivity
Test-NetConnection -ComputerName "ncp.nist.gov" -Port 443

# Check MCP server status
Invoke-WebRequest -Uri "http://localhost:8080/health"

# Validate configuration
Test-Json (Get-Content "config/settings.json" -Raw)
```

### Security Considerations

#### 1. **Network Security**
- NIST NCP Repository uses HTTPS
- MCP server supports TLS encryption
- Enterprise connections use authenticated channels

#### 2. **Data Privacy**
- No sensitive system data sent to NIST
- Compliance results cached locally
- Enterprise integration respects data governance

#### 3. **Authentication**
- NIST NCP Repository: Public API (no auth required)
- MCP Server: Optional API key authentication
- Enterprise Systems: Platform-specific authentication

### Next Steps

1. **Review Configuration**: Examine all JSON configuration files
2. **Test Integration**: Run connectivity tests and framework updates
3. **Customize Mappings**: Adjust NIST mappings for organization needs
4. **Plan Deployment**: Integrate with enterprise security platforms
5. **Monitor Performance**: Set up logging and monitoring for MCP services

### Support Resources

- **NIST NCP Repository**: https://ncp.nist.gov/repository
- **MCP Documentation**: Model Context Protocol specifications
- **STIG Assessment Tool**: Project documentation and guides
- **Enterprise Integration**: Platform-specific integration guides

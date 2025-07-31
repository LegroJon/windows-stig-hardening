# MCP Server Setup Guide
## Windows 11 STIG Assessment Tool - MCP Server Installation

### Overview
Yes, you absolutely need to start an MCP server for full functionality! The MCP (Model Context Protocol) server acts as the bridge between your STIG assessment tool and external systems like NIST NCP Repository, SIEM platforms, and GRC tools.

### MCP Server Options

#### Option 1: Use Existing MCP Server (Recommended)
Install a pre-built MCP server that supports the features we need:

```cmd
# Install MCP server via npm
npm install -g @modelcontextprotocol/server-everything

# Or install locally in project
cd mcp-server
npm init -y
npm install @modelcontextprotocol/server-everything express cors
```

#### Option 2: Custom MCP Server (Advanced)
Build a custom MCP server specifically for STIG/NIST integration.

### Quick Start Instructions

#### Step 1: Install MCP Server Dependencies
```cmd
# Create MCP server directory
mkdir mcp-server
cd mcp-server

# Initialize Node.js project
npm init -y

# Install required packages
npm install express cors axios node-cron winston helmet
npm install @modelcontextprotocol/sdk
```

#### Step 2: Start MCP Server
```cmd
# Option A: Use our custom server
node mcp-server.js

# Option B: Use pre-built server
npx @modelcontextprotocol/server-everything --port 8080
```

#### Step 3: Verify Server is Running
```powershell
# Test server health check
Invoke-WebRequest -Uri "http://localhost:8080/health"

# Or use our integration script
.\scripts\MCP-NISTIntegration.ps1 -TestConnection
```

### MCP Server Features Needed

1. **NIST NCP Repository Integration**
   - Fetch frameworks and controls
   - Cache management
   - Real-time updates

2. **STIG Assessment Integration**
   - Receive compliance results
   - Map to NIST frameworks
   - Generate reports

3. **Enterprise Connectivity**
   - SIEM integration endpoints
   - GRC platform connectors
   - Webhook notifications

4. **Security Features**
   - Authentication
   - Rate limiting
   - Audit logging

### Auto-Start Options

#### Option 1: Windows Service
Create a Windows service to auto-start MCP server on boot.

#### Option 2: Task Scheduler
Use Windows Task Scheduler for automatic startup.

#### Option 3: Docker Container
Run MCP server in Docker for easier management.

### Troubleshooting

**Server Not Starting:**
- Check if port 8080 is available
- Verify Node.js installation
- Check firewall settings

**Connection Issues:**
- Test network connectivity
- Verify NIST NCP repository access
- Check authentication credentials

### Next Steps

1. Choose MCP server option (custom vs pre-built)
2. Install and configure server
3. Test connectivity with STIG tool
4. Configure enterprise integrations
5. Set up monitoring and logging

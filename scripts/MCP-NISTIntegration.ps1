# MCP-NISTIntegration.ps1
# Model Context Protocol Integration with NIST NCP Repository
# Windows 11 STIG Assessment Tool - Enterprise Integration Module

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "$PSScriptRoot\..\config\settings.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableMCP,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableNISTIntegration,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestConnection,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateFrameworks
)

# Load configuration
function Get-STIGConfig {
    # Get the script directory and build the correct path
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptDir) {
        $scriptDir = $PSScriptRoot
    }
    $configPath = Join-Path (Split-Path -Parent $scriptDir) "config\settings.json"
    
    if (Test-Path $configPath) {
        return Get-Content $configPath | ConvertFrom-Json
    } else {
        Write-Host "[ERROR] Configuration file not found: $configPath" -ForegroundColor Red
        Write-Host "[INFO] Looking for: $configPath" -ForegroundColor Yellow
        Write-Host "[INFO] Current directory: $(Get-Location)" -ForegroundColor Yellow
        exit 1
    }
}

# Test NIST NCP Repository connectivity
function Test-NISTRepository {
    param([object]$Config)
    
    Write-Host "[INFO] Testing NIST NCP Repository connectivity..." -ForegroundColor Yellow
    
    try {
        $url = $Config.nist_ncp_integration.repository_url
        $response = Invoke-WebRequest -Uri $url -Method HEAD -TimeoutSec 10 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Host "[SUCCESS] NIST NCP Repository is accessible" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] NIST NCP Repository returned status: $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to connect to NIST NCP Repository: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Initialize MCP Server connection
function Initialize-MCPConnection {
    param([object]$Config)
    
    Write-Host "[INFO] Initializing MCP Server connection..." -ForegroundColor Yellow
    
    $mcpConfig = $Config.mcp_integration
    
    if (-not $mcpConfig.enabled) {
        Write-Host "[WARNING] MCP integration is disabled in configuration" -ForegroundColor Yellow
        return $false
    }
    
    try {
        # Test MCP server connectivity
        $serverUrl = "http://$($mcpConfig.server_url)"
        $response = Invoke-WebRequest -Uri "$serverUrl/health" -Method GET -TimeoutSec $mcpConfig.timeout_seconds -UseBasicParsing -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            Write-Host "[SUCCESS] MCP Server is running and accessible" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] MCP Server health check failed" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Cannot connect to MCP Server: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($mcpConfig.auto_start_server) {
            Write-Host "[INFO] Attempting to start MCP Server..." -ForegroundColor Yellow
            Start-MCPServer -Config $Config
        }
        
        return $false
    }
}

# Start MCP Server
function Start-MCPServer {
    param([object]$Config)
    
    Write-Host "[INFO] Starting MCP Server..." -ForegroundColor Yellow
    
    try {
        # Check if MCP server executable exists
        $mcpServerPath = "$PSScriptRoot\..\mcp-server\mcp-server.exe"
        
        if (-not (Test-Path $mcpServerPath)) {
            Write-Host "[ERROR] MCP Server executable not found: $mcpServerPath" -ForegroundColor Red
            Write-Host "[MANUAL] Please install MCP Server first" -ForegroundColor Yellow
            return $false
        }
        
        # Start MCP server as background process
        $process = Start-Process -FilePath $mcpServerPath -ArgumentList "--port 8080 --config $ConfigPath" -PassThru -NoNewWindow
        
        if ($process) {
            Write-Host "[SUCCESS] MCP Server started with PID: $($process.Id)" -ForegroundColor Green
            Start-Sleep -Seconds 5  # Allow server to initialize
            return $true
        } else {
            Write-Host "[ERROR] Failed to start MCP Server" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Error starting MCP Server: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get STIG rules from NIST NCP Repository
function Get-STIGRulesFromNIST {
    param(
        [object]$Config,
        [string]$Framework = "NIST-800-53"
    )
    
    Write-Host "[INFO] Retrieving STIG rules from NIST NCP Repository..." -ForegroundColor Yellow
    
    $nistConfig = $Config.nist_ncp_integration
    
    if (-not $nistConfig.enabled) {
        Write-Host "[WARNING] NIST NCP integration is disabled" -ForegroundColor Yellow
        return @()
    }
    
    try {
        $apiUrl = "$($nistConfig.api_endpoint)/frameworks/$Framework/controls"
        $headers = @{
            'Accept' = 'application/json'
            'User-Agent' = 'STIG-Assessment-Tool/1.0'
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Method GET -Headers $headers -TimeoutSec 30
        
        if ($response -and $response.controls) {
            Write-Host "[SUCCESS] Retrieved $($response.controls.Count) controls from NIST" -ForegroundColor Green
            return $response.controls
        } else {
            Write-Host "[WARNING] No controls returned from NIST API" -ForegroundColor Yellow
            return @()
        }
    } catch {
        Write-Host "[ERROR] Failed to retrieve NIST controls: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Send compliance results to MCP
function Send-ComplianceToMCP {
    param(
        [object]$Config,
        [array]$Results,
        [string]$ReportType = "compliance-assessment"
    )
    
    Write-Host "[INFO] Sending compliance results to MCP..." -ForegroundColor Yellow
    
    $mcpConfig = $Config.mcp_integration
    
    if (-not $mcpConfig.enabled) {
        Write-Host "[WARNING] MCP integration is disabled" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $serverUrl = "http://$($mcpConfig.server_url)"
        $endpoint = "$serverUrl/api/compliance/submit"
        
        $payload = @{
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            report_type = $ReportType
            system_info = @{
                hostname = $env:COMPUTERNAME
                domain = $env:USERDNSDOMAIN
                os_version = (Get-CimInstance Win32_OperatingSystem).Version
            }
            nist_mapping = $true
            results = $Results
        } | ConvertTo-Json -Depth 10
        
        $headers = @{
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }
        
        $response = Invoke-RestMethod -Uri $endpoint -Method POST -Body $payload -Headers $headers -TimeoutSec $mcpConfig.timeout_seconds
        
        if ($response.success) {
            Write-Host "[SUCCESS] Compliance results submitted to MCP" -ForegroundColor Green
            Write-Host "[INFO] MCP Report ID: $($response.report_id)" -ForegroundColor Cyan
            return $true
        } else {
            Write-Host "[ERROR] MCP rejected compliance submission: $($response.error)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to send results to MCP: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get organization baseline from NIST profiles
function Get-OrganizationBaseline {
    param(
        [object]$Config,
        [string]$ProfileType = "cybersecurity-framework"
    )
    
    Write-Host "[INFO] Retrieving organization baseline from NIST..." -ForegroundColor Yellow
    
    $nistConfig = $Config.nist_ncp_integration
    $orgConfig = $Config.organization_baseline
    
    if (-not $nistConfig.enabled -or -not $orgConfig.enabled) {
        Write-Host "[WARNING] NIST integration or organization baseline is disabled" -ForegroundColor Yellow
        return @()
    }
    
    try {
        $apiUrl = "$($nistConfig.api_endpoint)/profiles/$ProfileType/baseline"
        $headers = @{
            'Accept' = 'application/json'
            'User-Agent' = 'STIG-Assessment-Tool/1.0'
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Method GET -Headers $headers -TimeoutSec 30
        
        if ($response -and $response.baseline) {
            Write-Host "[SUCCESS] Retrieved organization baseline from NIST" -ForegroundColor Green
            return $response.baseline
        } else {
            Write-Host "[WARNING] No baseline returned from NIST API" -ForegroundColor Yellow
            return @()
        }
    } catch {
        Write-Host "[ERROR] Failed to retrieve NIST baseline: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Update NIST frameworks cache
function Update-NISTFrameworks {
    param([object]$Config)
    
    Write-Host "[INFO] Updating NIST frameworks cache..." -ForegroundColor Yellow
    
    $nistConfig = $Config.nist_ncp_integration
    
    if (-not $nistConfig.enabled) {
        Write-Host "[WARNING] NIST NCP integration is disabled" -ForegroundColor Yellow
        return $false
    }
    
    $cacheDir = "$PSScriptRoot\..\cache\nist"
    if (-not (Test-Path $cacheDir)) {
        New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
    }
    
    $frameworks = $nistConfig.framework_mappings.PSObject.Properties.Value | Sort-Object -Unique
    
    foreach ($framework in $frameworks) {
        try {
            Write-Host "[INFO] Updating framework: $framework" -ForegroundColor Cyan
            
            $controls = Get-STIGRulesFromNIST -Config $Config -Framework $framework
            
            if ($controls.Count -gt 0) {
                $cacheFile = "$cacheDir\$framework.json"
                $cacheData = @{
                    framework = $framework
                    updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
                    controls = $controls
                } | ConvertTo-Json -Depth 10
                
                Set-Content -Path $cacheFile -Value $cacheData -Encoding UTF8
                Write-Host "[SUCCESS] Cached $($controls.Count) controls for $framework" -ForegroundColor Green
            }
        } catch {
            Write-Host "[ERROR] Failed to update framework $framework`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    return $true
}

# Main execution logic
function Invoke-MCPNISTIntegration {
    Write-Host "[STIG] MCP-NIST Integration Module" -ForegroundColor Cyan
    Write-Host "[INFO] Initializing enterprise integration..." -ForegroundColor Yellow
    
    $config = Get-STIGConfig
    
    if ($TestConnection) {
        Write-Host "[INFO] Testing connections..." -ForegroundColor Yellow
        $nistResult = Test-NISTRepository -Config $config
        $mcpResult = Initialize-MCPConnection -Config $config
        
        Write-Host "`n[SUMMARY] Connection Test Results:" -ForegroundColor Cyan
        Write-Host "NIST NCP Repository: $(if ($nistResult) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($nistResult) { 'Green' } else { 'Red' })
        Write-Host "MCP Server: $(if ($mcpResult) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($mcpResult) { 'Green' } else { 'Red' })
        return
    }
    
    if ($UpdateFrameworks) {
        $updateResult = Update-NISTFrameworks -Config $config
        if ($updateResult) {
            Write-Host "[SUCCESS] NIST frameworks updated successfully" -ForegroundColor Green
        }
        return
    }
    
    if ($EnableMCP) {
        Write-Host "[INFO] Enabling MCP integration..." -ForegroundColor Yellow
        $config.mcp_integration.enabled = $true
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-Host "[SUCCESS] MCP integration enabled" -ForegroundColor Green
    }
    
    if ($EnableNISTIntegration) {
        Write-Host "[INFO] Enabling NIST NCP integration..." -ForegroundColor Yellow
        $config.nist_ncp_integration.enabled = $true
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-Host "[SUCCESS] NIST NCP integration enabled" -ForegroundColor Green
    }
    
    Write-Host "`n[INFO] Enterprise integration module ready" -ForegroundColor Green
    Write-Host "[NEXT] Run with -TestConnection to verify connectivity" -ForegroundColor Cyan
    Write-Host "[NEXT] Run with -UpdateFrameworks to cache NIST data" -ForegroundColor Cyan
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-MCPNISTIntegration
}

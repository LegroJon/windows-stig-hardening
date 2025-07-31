# MCP Server Startup Script for PowerShell
# Windows 11 STIG Assessment Tool - NIST NCP Repository Integration

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Development,
    
    [Parameter(Mandatory = $false)]
    [switch]$InstallDeps,
    
    [Parameter(Mandatory = $false)]
    [switch]$Background,
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080
)

function Test-NodeJS {
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Host "[SUCCESS] Node.js is installed: $nodeVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "[ERROR] Node.js is not installed or not in PATH" -ForegroundColor Red
        Write-Host "[MANUAL] Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
        return $false
    }
}

function Install-Dependencies {
    Write-Host "[INFO] Installing MCP server dependencies..." -ForegroundColor Yellow
    
    try {
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Dependencies installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] npm install failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Start-MCPServer {
    param([bool]$DevMode, [bool]$BackgroundMode, [int]$ServerPort)
    
    $args = @()
    if ($DevMode) {
        $args += "--dev"
    }
    
    $env:PORT = $ServerPort
    
    Write-Host "[STIG] Starting MCP Server..." -ForegroundColor Cyan
    Write-Host "[INFO] Port: $ServerPort" -ForegroundColor Yellow
    Write-Host "[INFO] Mode: $(if ($DevMode) { 'Development' } else { 'Production' })" -ForegroundColor Yellow
    Write-Host "[INFO] Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        if ($BackgroundMode) {
            $process = Start-Process -FilePath "node" -ArgumentList ("server.js" + $args) -PassThru -NoNewWindow
            Write-Host "[SUCCESS] MCP Server started in background with PID: $($process.Id)" -ForegroundColor Green
            Write-Host "[INFO] Health check: http://localhost:$ServerPort/health" -ForegroundColor Cyan
            return $process
        } else {
            node server.js @args
        }
    } catch {
        Write-Host "[ERROR] Failed to start MCP server: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "[STIG] MCP Server Startup Script" -ForegroundColor Cyan
Write-Host "[INFO] NIST NCP Repository Integration Server" -ForegroundColor Yellow

# Change to script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Test Node.js installation
if (-not (Test-NodeJS)) {
    exit 1
}

# Check for package.json
if (-not (Test-Path "package.json")) {
    Write-Host "[ERROR] package.json not found in current directory" -ForegroundColor Red
    Write-Host "[INFO] Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Install dependencies if requested or if node_modules doesn't exist
if ($InstallDeps -or -not (Test-Path "node_modules")) {
    if (-not (Install-Dependencies)) {
        exit 1
    }
}

# Check for server.js
if (-not (Test-Path "server.js")) {
    Write-Host "[ERROR] server.js not found" -ForegroundColor Red
    exit 1
}

# Test port availability
try {
    $portTest = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($portTest) {
        Write-Host "[WARNING] Port $Port appears to be in use" -ForegroundColor Yellow
        Write-Host "[INFO] MCP server may already be running" -ForegroundColor Yellow
    }
} catch {
    # Port is available (this is what we want)
}

# Start the server
$result = Start-MCPServer -DevMode $Development -BackgroundMode $Background -ServerPort $Port

if ($Background -and $result) {
    Write-Host "[NEXT] Use 'Stop-Process -Id $($result.Id)' to stop the server" -ForegroundColor Cyan
    Write-Host "[NEXT] Test connectivity with: .\scripts\MCP-NISTIntegration.ps1 -TestConnection" -ForegroundColor Cyan
} elseif (-not $Background) {
    Write-Host "`n[INFO] MCP Server stopped" -ForegroundColor Yellow
}

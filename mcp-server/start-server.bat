@echo off
REM MCP Server Startup Script for Windows 11 STIG Assessment Tool
REM NIST NCP Repository Integration Server

echo [STIG] Starting MCP Server...
echo [INFO] NIST NCP Repository Integration Server

REM Change to MCP server directory
cd /d "%~dp0"

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo [MANUAL] Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if package.json exists
if not exist "package.json" (
    echo [ERROR] package.json not found in current directory
    echo [INFO] Current directory: %cd%
    pause
    exit /b 1
)

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo [INFO] Installing MCP server dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
    echo [SUCCESS] Dependencies installed
)

REM Check if server.js exists
if not exist "server.js" (
    echo [ERROR] server.js not found
    pause
    exit /b 1
)

REM Start the MCP server
echo [INFO] Starting MCP Server on port 8080...
echo [INFO] Use the PowerShell script for more options: ..\scripts\Start-MCPServer.ps1
echo [INFO] Press Ctrl+C to stop the server
echo.

node server.js

REM If we get here, the server has stopped
echo.
echo [INFO] MCP Server stopped
pause

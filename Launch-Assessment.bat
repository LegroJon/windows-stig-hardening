@echo off
REM Windows 11 STIG Assessment Tool - Batch Launcher
REM Automatically handles PowerShell execution policy issues

echo [STIG] Windows 11 STIG Assessment Tool - Batch Launcher
echo ================================================

REM Check if PowerShell is available
powershell -Command "Write-Host '[SUCCESS] PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell is not available or accessible
    echo [INFO] This tool requires PowerShell 5.1 or higher
    pause
    exit /b 1
)

echo [INFO] Starting STIG assessment with automatic execution policy handling...
echo [SECURITY] This will temporarily allow PowerShell script execution for this session only
echo.

REM Launch PowerShell with execution policy bypass
powershell -ExecutionPolicy Bypass -Command "& '.\Launch-Assessment.ps1'"

REM Check exit code
if errorlevel 1 (
    echo.
    echo [ERROR] Assessment tool encountered an error
    echo [TROUBLESHOOTING] Try running PowerShell as Administrator
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Assessment completed successfully
echo [INFO] Check the reports folder for assessment results
pause

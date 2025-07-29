@echo off
echo Windows 11 STIG Assessment Tool - Admin Launcher
echo ================================================
echo.
echo Requesting Administrator privileges...
echo.

:: Check if already running as admin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Already running with administrator privileges.
    goto :run_assessment
)

:: Request elevation
echo Requesting UAC elevation...
powershell -Command "Start-Process cmd -ArgumentList '/c cd /d \"%~dp0\" && powershell -ExecutionPolicy Bypass -File \".\scripts\Start-STIGAssessment.ps1\" && pause' -Verb RunAs"
goto :end

:run_assessment
echo Running STIG Assessment...
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\scripts\Start-STIGAssessment.ps1"
pause

:end

<#
.SYNOPSIS
    Requests administrator privileges for the current PowerShell session

.DESCRIPTION
    This script checks if the current session has administrator privileges and
    if not, restarts the session with elevated rights. Useful for running
    STIG assessments that require system-level access.

.PARAMETER ScriptToRun
    Optional script to run after elevation

.PARAMETER Arguments
    Arguments to pass to the elevated script

.EXAMPLE
    .\Request-AdminRights.ps1
    Just elevate current session

.EXAMPLE
    .\Request-AdminRights.ps1 -ScriptToRun "Start-STIGAssessment.ps1"
    Elevate and run a specific script
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ScriptToRun,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Arguments = @()
)

function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    param(
        [string]$TargetScript,
        [string[]]$ScriptArgs
    )
    
    Write-Host "`n🛡️ Administrator Privileges Required" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Yellow
    Write-Host "This operation requires administrator privileges." -ForegroundColor White
    Write-Host "Windows will prompt for elevation (UAC)..." -ForegroundColor Gray
    
    try {
        $processArgs = @(
            "-ExecutionPolicy", "Bypass",
            "-NoProfile"
        )
        
        if ($TargetScript) {
            $processArgs += "-File", "`"$TargetScript`""
            if ($ScriptArgs) {
                $processArgs += $ScriptArgs
            }
        } else {
            $processArgs += "-NoExit"
            $processArgs += "-Command", "cd `"$PWD`"; Write-Host 'Administrator PowerShell session started.' -ForegroundColor Green"
        }
        
        Write-Host "`nStarting elevated PowerShell session..." -ForegroundColor Green
        Start-Process -FilePath "PowerShell.exe" -Verb RunAs -ArgumentList $processArgs
        
        if ($TargetScript) {
            Write-Host "Elevated script started. This window will now close." -ForegroundColor Gray
            exit 0
        } else {
            Write-Host "New elevated session opened. You can close this window." -ForegroundColor Gray
            exit 0
        }
    }
    catch {
        Write-Host "`n[ERROR] Failed to request elevation: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please manually run PowerShell as Administrator." -ForegroundColor Yellow
        exit 1
    }
}

# Main execution
Write-Host "`nWindows 11 STIG Assessment Tool - Admin Rights Check" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

if (Test-IsAdministrator) {
    Write-Host "`n✅ Already running with administrator privileges!" -ForegroundColor Green
    
    if ($ScriptToRun) {
        Write-Host "Executing: $ScriptToRun" -ForegroundColor White
        
        $scriptPath = if ([System.IO.Path]::IsPathRooted($ScriptToRun)) {
            $ScriptToRun
        } else {
            Join-Path $PWD $ScriptToRun
        }
        
        if (Test-Path $scriptPath) {
            & $scriptPath @Arguments
        } else {
            Write-Host "[ERROR] Script not found: $scriptPath" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Ready to run administrative commands." -ForegroundColor White
    }
} else {
    Request-Elevation -TargetScript $ScriptToRun -ScriptArgs $Arguments
}

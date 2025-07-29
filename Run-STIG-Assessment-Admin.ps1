<#
.SYNOPSIS
    Admin Launcher for Windows 11 STIG Assessment Tool

.DESCRIPTION
    This script handles UAC elevation and runs the STIG assessment with administrator privileges.
    It provides multiple methods to ensure reliable elevation.
#>

function Test-IsElevated {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    param([string]$ScriptPath)
    
    Write-Host "🛡️ Windows 11 STIG Assessment Tool - Admin Launcher" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    if (Test-IsElevated) {
        Write-Host "✅ Already running with administrator privileges" -ForegroundColor Green
        return $true
    }
    
    Write-Host "🔒 Administrator privileges required for accurate STIG assessment" -ForegroundColor Yellow
    Write-Host "📋 This will check real Windows security settings, not mock data" -ForegroundColor Gray
    Write-Host ""
    
    try {
        Write-Host "🚀 Requesting UAC elevation..." -ForegroundColor Yellow
        
        # Method 1: Direct PowerShell elevation
        $arguments = @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$ScriptPath`""
        )
        
        Start-Process -FilePath "PowerShell.exe" -ArgumentList $arguments -Verb "RunAs" -Wait
        return $true
    }
    catch {
        Write-Host "❌ Method 1 failed: $($_.Exception.Message)" -ForegroundColor Red
        
        try {
            # Method 2: CMD wrapper approach
            Write-Host "🔄 Trying alternative elevation method..." -ForegroundColor Yellow
            
            $cmdArgs = "/c `"cd /d `"$PSScriptRoot`" && powershell -ExecutionPolicy Bypass -File `"$ScriptPath`" && pause`""
            Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -Verb "RunAs"
            return $true
        }
        catch {
            Write-Host "❌ Method 2 failed: $($_.Exception.Message)" -ForegroundColor Red
            
            # Method 3: Manual instructions
            Write-Host "🔧 Manual Elevation Required:" -ForegroundColor Red
            Write-Host "1. Right-click Start button" -ForegroundColor White
            Write-Host "2. Select 'Windows PowerShell (Admin)'" -ForegroundColor White
            Write-Host "3. Navigate to: $PSScriptRoot" -ForegroundColor White
            Write-Host "4. Run: .\scripts\Start-STIGAssessment.ps1" -ForegroundColor White
            return $false
        }
    }
}

# Main execution
$assessmentScript = Join-Path $PSScriptRoot "scripts\Start-STIGAssessment.ps1"

if (-not (Test-Path $assessmentScript)) {
    Write-Host "❌ Assessment script not found: $assessmentScript" -ForegroundColor Red
    Write-Host "Please ensure you're running this from the project root directory." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

if (Test-IsElevated) {
    # Already elevated, run directly
    Write-Host "✅ Running STIG Assessment with administrator privileges..." -ForegroundColor Green
    & $assessmentScript
} else {
    # Need elevation
    $success = Request-Elevation -ScriptPath $assessmentScript
    if (-not $success) {
        Read-Host "Press Enter to exit"
    }
}

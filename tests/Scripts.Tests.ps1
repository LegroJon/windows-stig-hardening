# Unit Tests for CLI Scripts
# Tests the command-line interface scripts for proper functionality

BeforeAll {
    # Load test settings and mocks
    . "$PSScriptRoot\TestSettings.ps1"
    . "$PSScriptRoot\Mocks.ps1"
    
    # Set up test environment
    $scriptsPath = Join-Path $PSScriptRoot "..\scripts"
}

Describe "Test-Prerequisites.ps1" {
    
    Context "Basic Functionality" {
        
        It "Should exist and be readable" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            Test-Path $scriptPath | Should -Be $true
            
            # Test that file can be read
            $content = Get-Content $scriptPath -ErrorAction SilentlyContinue
            $content | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid PowerShell syntax" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            
            # Test syntax by parsing the file
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath, [ref]$tokens, [ref]$errors
            )
            
            $errors.Count | Should -Be 0
        }
        
        It "Should contain help documentation" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "\.SYNOPSIS"
            $content | Should -Match "\.DESCRIPTION"
            $content | Should -Match "\.EXAMPLE"
        }
        
        It "Should accept Detailed parameter" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "\[switch\]\s*\$Detailed"
        }
    }
    
    Context "Prerequisites Checking Logic" {
        
        BeforeEach {
            # Mock system information
            Mock Get-CimInstance {
                return Mock-OSInfo -OSVersion "Windows11"
            } -ParameterFilter { $ClassName -eq "Win32_OperatingSystem" }
            
            Mock Get-Module {
                return @{ Name = "Pester"; Version = "5.3.0" }
            } -ParameterFilter { $Name -eq "Pester" }
        }
        
        It "Should detect Windows 11 correctly" {
            # This would require running the actual script in a controlled way
            # For now, we'll test the logic patterns exist
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "Windows 11"
            $content | Should -Match "Get-CimInstance.*Win32_OperatingSystem"
        }
        
        It "Should check PowerShell version" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "\$PSVersionTable"
            $content | Should -Match "5\.1"
        }
        
        It "Should check administrator privileges" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "WindowsIdentity"
            $content | Should -Match "Administrator"
        }
        
        It "Should check execution policy" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "Get-ExecutionPolicy"
            $content | Should -Match "RemoteSigned|Unrestricted|Bypass"
        }
    }
    
    Context "Output Formatting" {
        
        It "Should have colored output functions" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "Write-Host.*-ForegroundColor"
            $content | Should -Match "Green|Red|Yellow|Cyan"
        }
        
        It "Should provide summary information" {
            $scriptPath = Join-Path $scriptsPath "Test-Prerequisites.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "Overall Status"
            $content | Should -Match "\[PASS\]|\[FAIL\]"
        }
    }
}

Describe "Start-STIGAssessment.ps1" {
    
    Context "Basic Functionality" {
        
        It "Should exist and be readable" {
            $scriptPath = Join-Path $scriptsPath "Start-STIGAssessment.ps1"
            Test-Path $scriptPath | Should -Be $true
        }
        
        It "Should have valid PowerShell syntax" {
            $scriptPath = Join-Path $scriptsPath "Start-STIGAssessment.ps1"
            
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath, [ref]$tokens, [ref]$errors
            )
            
            $errors.Count | Should -Be 0
        }
        
        It "Should contain help documentation" {
            $scriptPath = Join-Path $scriptsPath "Start-STIGAssessment.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "\.SYNOPSIS"
            $content | Should -Match "\.DESCRIPTION"
            $content | Should -Match "\.EXAMPLE"
        }
        
        It "Should accept required parameters" {
            $scriptPath = Join-Path $scriptsPath "Start-STIGAssessment.ps1"
            $content = Get-Content $scriptPath -Raw
            
            # Check for common parameters that would be expected
            $content | Should -Match "param\s*\("
        }
    }
    
    Context "Configuration Loading" {
        
        It "Should reference configuration files" {
            $scriptPath = Join-Path $scriptsPath "Start-STIGAssessment.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "config|settings\.json"
        }
        
        It "Should handle missing configuration gracefully" {
            # This would test error handling for missing config files
            $scriptPath = Join-Path $scriptsPath "Start-STIGAssessment.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "Test-Path|try.*catch"
        }
    }
}

Describe "Install-TestingTools.ps1" {
    
    Context "Basic Functionality" {
        
        It "Should exist and be readable" {
            $scriptPath = Join-Path $scriptsPath "Install-TestingTools.ps1"
            Test-Path $scriptPath | Should -Be $true
        }
        
        It "Should have valid PowerShell syntax" {
            $scriptPath = Join-Path $scriptsPath "Install-TestingTools.ps1"
            
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath, [ref]$tokens, [ref]$errors
            )
            
            $errors.Count | Should -Be 0
        }
        
        It "Should reference required testing modules" {
            $scriptPath = Join-Path $scriptsPath "Install-TestingTools.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "Pester"
            $content | Should -Match "PSScriptAnalyzer"
        }
        
        It "Should handle installation errors" {
            $scriptPath = Join-Path $scriptsPath "Install-TestingTools.ps1"
            $content = Get-Content $scriptPath -Raw
            
            $content | Should -Match "try.*catch|ErrorAction"
        }
    }
}

Describe "Script Integration" {
    
    Context "Cross-Script Dependencies" {
        
        It "Should have consistent file paths across scripts" {
            $scripts = Get-ChildItem -Path $scriptsPath -Filter "*.ps1"
            
            foreach ($script in $scripts) {
                $content = Get-Content $script.FullName -Raw
                
                # Check for relative path consistency
                if ($content -match "\.\./") {
                    # Paths should be consistent with project structure
                    $content | Should -Not -Match "\.\./\.\./\.\."  # No excessive nesting
                }
            }
        }
        
        It "Should reference existing directories" {
            $scriptPath = Join-Path $scriptsPath "Start-STIGAssessment.ps1"
            
            if (Test-Path $scriptPath) {
                $content = Get-Content $scriptPath -Raw
                
                # If script references specific directories, they should exist
                if ($content -match "rules/core|config") {
                    $projectRoot = Split-Path $scriptsPath -Parent
                    Test-Path (Join-Path $projectRoot "rules\core") | Should -Be $true
                    Test-Path (Join-Path $projectRoot "config") | Should -Be $true
                }
            }
        }
    }
}

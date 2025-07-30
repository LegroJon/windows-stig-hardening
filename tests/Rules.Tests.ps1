# Unit Tests for STIG Rules
# Tests the individual STIG rule functions to ensure they work correctly

# Import required modules and test dependencies
BeforeAll {
    # Load test settings and mocks
    . "$PSScriptRoot\TestSettings.ps1"
    . "$PSScriptRoot\Mocks.ps1"
    
    # Import the rule modules
    $rulePath = Join-Path $PSScriptRoot "..\rules\core"
    Get-ChildItem -Path $rulePath -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
}

Describe "STIG Rule Tests" {
    
    Context "WN11-SO-000001: Disable SMBv1 Protocol" {
        
        BeforeEach {
            # Reset any previous mocks
            InModuleScope Pester { $PesterState.CurrentTest = $null }
        }
        
        It "Should return Compliant when SMBv1 is disabled" {
            # Arrange
            Mock Get-WindowsOptionalFeature {
                return Mock-WindowsOptionalFeature -FeatureName "SMB1Protocol" -State "Disabled"
            }
            
            # Act
            $result = Test-DisableSMBv1
            
            # Assert
            $result.RuleID | Should -Be "WN11-SO-000001"
            $result.Status | Should -Be "Compliant"
            $result.Evidence | Should -Match "SMB1Protocol State: Disabled"
            $result.FixText | Should -Not -BeNullOrEmpty
        }
        
        It "Should return Non-Compliant when SMBv1 is enabled" {
            # Arrange
            Mock Get-WindowsOptionalFeature {
                return Mock-WindowsOptionalFeature -FeatureName "SMB1Protocol" -State "Enabled"
            }
            
            # Act
            $result = Test-DisableSMBv1
            
            # Assert
            $result.RuleID | Should -Be "WN11-SO-000001"
            $result.Status | Should -Be "Non-Compliant"
            $result.Evidence | Should -Match "SMB1Protocol State: Enabled"
            $result.FixText | Should -Match "Disable-WindowsOptionalFeature"
        }
        
        It "Should return Error status when Get-WindowsOptionalFeature fails" {
            # Arrange
            Mock Get-WindowsOptionalFeature {
                throw "Access denied"
            }
            
            # Act
            $result = Test-DisableSMBv1
            
            # Assert
            $result.RuleID | Should -Be "WN11-SO-000001"
            $result.Status | Should -Be "Error"
            $result.Evidence | Should -Match "Error checking SMB1Protocol"
            $result.FixText | Should -Match "Manually verify"
        }
        
        It "Should execute within performance threshold" {
            # Arrange
            Mock Get-WindowsOptionalFeature {
                return Mock-WindowsOptionalFeature -FeatureName "SMB1Protocol" -State "Disabled"
            }
            
            # Act & Assert
            $executionTime = Measure-Command { Test-DisableSMBv1 }
            $executionTime.TotalMilliseconds | Should -BeLessThan $Global:TestSettings.Performance.MaxRuleExecutionTimeMs
        }
    }
    
    Context "Rule Structure Validation" {
        
        It "Should have consistent return structure across all rules" {
            # Test that all rules return the expected properties
            
            Mock Get-WindowsOptionalFeature {
                return Mock-WindowsOptionalFeature -FeatureName "SMB1Protocol" -State "Disabled"
            }
            
            $result = Test-DisableSMBv1
            
            # Verify required properties exist
            $result | Should -HaveProperty RuleID
            $result | Should -HaveProperty Status
            $result | Should -HaveProperty Evidence
            $result | Should -HaveProperty FixText
            
            # Verify property types
            $result.RuleID | Should -BeOfType [string]
            $result.Status | Should -BeOfType [string]
            $result.Evidence | Should -BeOfType [string]
            $result.FixText | Should -BeOfType [string]
        }
        
        It "Should have valid status values" {
            Mock Get-WindowsOptionalFeature {
                return Mock-WindowsOptionalFeature -FeatureName "SMB1Protocol" -State "Disabled"
            }
            
            $result = Test-DisableSMBv1
            $validStatuses = @("Compliant", "Non-Compliant", "Error", "Not Applicable")
            
            $result.Status | Should -BeIn $validStatuses
        }
        
        It "Should have properly formatted Rule IDs" {
            Mock Get-WindowsOptionalFeature {
                return Mock-WindowsOptionalFeature -FeatureName "SMB1Protocol" -State "Disabled"
            }
            
            $result = Test-DisableSMBv1
            
            # Rule ID should match format: WN11-XX-000000
            $result.RuleID | Should -Match "^WN11-[A-Z]{2}-\d{6}$"
        }
    }
    
    Context "Error Handling" {
        
        It "Should handle null responses gracefully" {
            Mock Get-WindowsOptionalFeature {
                return $null
            }
            
            $result = Test-DisableSMBv1
            $result.Status | Should -Be "Error"
        }
        
        It "Should handle unexpected property values" {
            Mock Get-WindowsOptionalFeature {
                return @{ State = "Unknown"; SomeOtherProperty = "Value" }
            }
            
            $result = Test-DisableSMBv1
            $result | Should -Not -BeNullOrEmpty
            $result.RuleID | Should -Be "WN11-SO-000001"
        }
    }
}

Describe "Rule Discovery and Loading" {
    
    Context "Rule File Structure" {
        
        It "Should find rule files in core directory" {
            $coreRulesPath = Join-Path $PSScriptRoot "..\rules\core"
            $ruleFiles = Get-ChildItem -Path $coreRulesPath -Filter "*.ps1" -Exclude "README*"
            
            $ruleFiles.Count | Should -BeGreaterThan 0
        }
        
        It "Should have properly named rule files" {
            $coreRulesPath = Join-Path $PSScriptRoot "..\rules\core"
            $ruleFiles = Get-ChildItem -Path $coreRulesPath -Filter "*.ps1" -Exclude "README*"
            
            foreach ($file in $ruleFiles) {
                # Rule files should match pattern: WN11-XX-000000.ps1
                $file.BaseName | Should -Match "^WN11-[A-Z]{2}-\d{6}$"
            }
        }
        
        It "Should contain valid PowerShell syntax" {
            $coreRulesPath = Join-Path $PSScriptRoot "..\rules\core"
            $ruleFiles = Get-ChildItem -Path $coreRulesPath -Filter "*.ps1" -Exclude "README*"
            
            foreach ($file in $ruleFiles) {
                # Test that the file can be parsed without syntax errors
                { . $file.FullName } | Should -Not -Throw
            }
        }
    }
}

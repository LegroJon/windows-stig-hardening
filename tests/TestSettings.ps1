# Test Configuration and Settings
# This file contains shared configuration for all test files

# Test execution settings
$TestSettings = @{
    # Pester configuration
    Pester = @{
        OutputFormat = "NUnitXml"
        OutputPath = "./tests/results/"
        CodeCoverage = @{
            Enabled = $true
            OutputPath = "./tests/results/coverage.xml"
            OutputFormat = "JaCoCo"
        }
        TestResult = @{
            Enabled = $true
            OutputPath = "./tests/results/testresults.xml"
        }
    }
    
    # Mock data and test constants
    TestData = @{
        ValidRuleID = "WN11-SO-000001"
        InvalidRuleID = "INVALID-001"
        SampleSMBState = @{
            Disabled = @{ State = "Disabled"; RestartRequired = $false }
            Enabled = @{ State = "Enabled"; RestartRequired = $false }
        }
        SampleOSInfo = @{
            Windows11 = @{ 
                Caption = "Microsoft Windows 11 Enterprise"
                Version = "10.0.22621"
                OSArchitecture = "64-bit"
            }
            Windows10 = @{
                Caption = "Microsoft Windows 10 Enterprise"
                Version = "10.0.19045"
                OSArchitecture = "64-bit"
            }
        }
    }
    
    # Paths for testing
    Paths = @{
        RulesCore = "./rules/core"
        RulesCustom = "./rules/custom"
        Scripts = "./scripts"
        Config = "./config"
        TestResults = "./tests/results"
        TestData = "./tests/data"
    }
    
    # Performance thresholds
    Performance = @{
        MaxRuleExecutionTimeMs = 5000  # 5 seconds max per rule
        MaxFullScanTimeMs = 300000     # 5 minutes max for full scan
        MaxMemoryUsageMB = 512         # 512MB max memory usage
    }
}

# Create test results directory if it doesn't exist
if (-not (Test-Path $TestSettings.TestResults)) {
    New-Item -Path $TestSettings.TestResults -ItemType Directory -Force | Out-Null
}

# Export settings for use in test files
$Global:TestSettings = $TestSettings

Write-Verbose "Test settings loaded successfully"
Write-Verbose "Test results will be saved to: $($TestSettings.Paths.TestResults)"

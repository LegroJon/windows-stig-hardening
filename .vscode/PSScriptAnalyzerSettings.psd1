@{
    # Use Severity levels to comply with PowerShell Gallery
    Severity = @('Error', 'Warning', 'Information')

    # Include default rules
    IncludeDefaultRules = $true

    # Exclude specific rules that don't apply to this project
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingPositionalParameters'
    )

    # Custom rules for STIG project
    Rules = @{
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }
        PSUsePSCredentialType = @{
            Enable = $true
        }
        PSAvoidUsingUsernameAndPasswordParams = @{
            Enable = $true
        }
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }
        PSUseCmdletCorrectly = @{
            Enable = $true
        }
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $false
            BlockComment = $true
            VSCodeSnippetCorrection = $true
            Placement = "before"
        }
    }
}

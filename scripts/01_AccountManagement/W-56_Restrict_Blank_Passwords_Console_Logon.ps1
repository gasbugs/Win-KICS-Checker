<#
.SYNOPSIS
    Checks if the 'Accounts: Limit local account use of blank passwords to console logon only' policy is enabled.

.DESCRIPTION
    This script verifies if the security policy 'Accounts: Limit local account use of blank passwords to console logon only'
    is set to 'Enabled'. This prevents local accounts with blank passwords from being used for network logons.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W56RestrictBlankPasswordsConsoleLogon {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-56"
    $category = "Account Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $limitBlankPasswordUse = ($content | Select-String -Pattern "LimitBlankPasswordUse" | ForEach-Object { $_.ToString().Split('=')[1].Split(',')[1].Trim() }) -as [int]

        if ($limitBlankPasswordUse -eq 1) {
            $details = "The 'Accounts: Limit local account use of blank passwords to console logon only' policy is enabled."
        } else {
            $result = "Vulnerable"
            $details = "The 'Accounts: Limit local account use of blank passwords to console logon only' policy is disabled (Current value: $limitBlankPasswordUse)."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking the policy: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W56RestrictBlankPasswordsConsoleLogon

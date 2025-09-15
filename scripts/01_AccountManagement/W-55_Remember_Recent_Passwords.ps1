<#
.SYNOPSIS
    Checks if the 'Enforce password history' policy is set to 4 or more passwords.

.DESCRIPTION
    This script verifies if the security policy 'Enforce password history'
    is configured to remember 4 or more unique passwords, preventing users from reusing recent passwords.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W55RememberRecentPasswords {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-55"
    $category = "Account Management"
    $result = "Good"
    $details = ""
    $minRecommendedHistory = 4

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $passwordHistorySize = ($content | Select-String -Pattern "PasswordHistorySize" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($passwordHistorySize -ge $minRecommendedHistory) {
            $details = "The 'Enforce password history' policy is set to remember $passwordHistorySize passwords (Recommended: >= $minRecommendedHistory)."
        } else {
            $result = "Vulnerable"
            $details = "The 'Enforce password history' policy is set to remember $passwordHistorySize passwords, which is less than the recommended $minRecommendedHistory."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking password history policy: $($_.Exception.Message)"
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
Test-W55RememberRecentPasswords

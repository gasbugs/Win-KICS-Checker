<#
.SYNOPSIS
    Checks if the 'Minimum password length' policy is set to 8 characters or more.

.DESCRIPTION
    This script verifies if the security policy 'Minimum password length'
    is configured to 8 characters or more, as recommended for stronger passwords.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W49MinimumPasswordLength {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-49"
    $category = "Account Management"
    $result = "Good"
    $details = ""
    $minRecommendedLength = 8

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $minimumPasswordLength = ($content | Select-String -Pattern "MinimumPasswordLength" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($minimumPasswordLength -ge $minRecommendedLength) {
            $details = "The 'Minimum password length' policy is set to $minimumPasswordLength characters (Recommended: >= $minRecommendedLength)."
        } else {
            $result = "Vulnerable"
            $details = "The 'Minimum password length' policy is set to $minimumPasswordLength characters, which is less than the recommended $minRecommendedLength characters."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking minimum password length policy: $($_.Exception.Message)"
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
Test-W49MinimumPasswordLength

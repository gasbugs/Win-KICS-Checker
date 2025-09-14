<#
.SYNOPSIS
    Checks if the 'Minimum password age' policy is set to a value greater than 0.

.DESCRIPTION
    This script verifies if the security policy 'Minimum password age'
    is configured to a value greater than 0 (e.g., 1 day or more), as recommended.
    A value of 0 allows users to immediately change their password back to a previous one,
    reducing security effectiveness.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W51MinimumPasswordAge {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-51"
    $category = "Account Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $minimumPasswordAge = ($content | Select-String -Pattern "MinimumPasswordAge = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($minimumPasswordAge -gt 0) {
            $details = "The 'Minimum password age' policy is set to $($minimumPasswordAge / (24*60*60)) days (Recommended: > 0 days)."
        } else {
            $result = "Vulnerable"
            $details = "The 'Minimum password age' policy is set to 0 days, allowing immediate password changes back to previous ones."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking minimum password age policy: $($_.Exception.Message)"
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
Test-W51MinimumPasswordAge

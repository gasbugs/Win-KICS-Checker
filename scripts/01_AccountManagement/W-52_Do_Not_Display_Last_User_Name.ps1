<#
.SYNOPSIS
    Checks if the 'Interactive logon: Do not display last user name' policy is enabled.

.DESCRIPTION
    This script verifies if the security policy 'Interactive logon: Do not display last user name'
    is set to 'Enabled'. This prevents the last logged-on user's name from being displayed
    on the logon screen, reducing information disclosure.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W52DoNotDisplayLastUserName {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-52"
    $category = "Account Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $dontDisplayLastUserName = ($content | Select-String -Pattern "DontDisplayLastUserName = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($dontDisplayLastUserName -eq 1) {
            $details = "The 'Interactive logon: Do not display last user name' policy is enabled."
        } else {
            $result = "Vulnerable"
            $details = "The 'Interactive logon: Do not display last user name' policy is disabled (Current value: $dontDisplayLastUserName)."
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
Test-W52DoNotDisplayLastUserName

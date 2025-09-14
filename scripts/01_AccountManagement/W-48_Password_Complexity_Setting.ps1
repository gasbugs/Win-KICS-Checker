<#
.SYNOPSIS
    Checks if the 'Password must meet complexity requirements' policy is enabled.

.DESCRIPTION
    This script verifies if the security policy 'Password must meet complexity requirements'
    is set to 'Enabled'. This policy enforces stronger password rules.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W48PasswordComplexitySetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-48"
    $category = "Account Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $passwordComplexity = ($content | Select-String -Pattern "PasswordComplexity = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($passwordComplexity -eq 1) {
            $details = "The 'Password must meet complexity requirements' policy is enabled."
        } else {
            $result = "Vulnerable"
            $details = "The 'Password must meet complexity requirements' policy is disabled (Current value: $passwordComplexity)."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking password complexity policy: $($_.Exception.Message)"
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
Test-W48PasswordComplexitySetting

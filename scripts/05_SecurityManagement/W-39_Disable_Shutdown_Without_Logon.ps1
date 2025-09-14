<#
.SYNOPSIS
    Checks if the 'Shutdown: Allow system to be shut down without having to log on' policy is disabled.

.DESCRIPTION
    This script verifies if the security policy 'Shutdown: Allow system to be shut down without having to log on'
    is set to 'Disabled'. This prevents unauthorized users from shutting down the system from the logon screen.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W39DisableShutdownWithoutLogon {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-39"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $shutdownWithoutLogon = ($content | Select-String -Pattern "ShutdownWithoutLogon = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($shutdownWithoutLogon -eq 0) {
            $details = "The 'Shutdown: Allow system to be shut down without having to log on' policy is disabled."
        } else {
            $result = "Vulnerable"
            $details = "The 'Shutdown: Allow system to be shut down without having to log on' policy is enabled (Current value: $shutdownWithoutLogon)."
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
Test-W39DisableShutdownWithoutLogon

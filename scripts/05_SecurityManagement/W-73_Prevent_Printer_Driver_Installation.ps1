<#
.SYNOPSIS
    Checks if the 'Devices: Prevent users from installing printer drivers' policy is enabled.

.DESCRIPTION
    This script verifies if the security policy 'Devices: Prevent users from installing printer drivers'
    is set to 'Enabled'. This prevents non-administrative users from installing printer drivers,
    which can be a vector for malware or system instability.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W73PreventPrinterDriverInstallation {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-73"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $preventDriverInstallation = ($content | Select-String -Pattern "PreventDriverInstallation" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($preventDriverInstallation -eq 1) {
            $details = "The 'Devices: Prevent users from installing printer drivers' policy is enabled."
        } else {
            $result = "Vulnerable"
            $details = "The 'Devices: Prevent users from installing printer drivers' policy is disabled (Current value: $preventDriverInstallation)."
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
Test-W73PreventPrinterDriverInstallation

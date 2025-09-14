<#
.SYNOPSIS
    Checks if the screensaver is enabled, set to 10 minutes or less, and password protected.

.DESCRIPTION
    This script verifies the screensaver settings by checking relevant security policies.
    It ensures that the screensaver is activated, locks the workstation after a short idle period,
    and requires a password to unlock, preventing unauthorized access during user absence.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W38ScreensaverSetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-38"
    $category = "Security Management"
    $result = "Good"
    $details = @()
    $maxIdleTimeSeconds = 600 # 10 minutes

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $screenSaverIsSecure = ($content | Select-String -Pattern "ScreenSaverIsSecure = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $screenSaverTimeout = ($content | Select-String -Pattern "ScreenSaverTimeout = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $screenSaveActive = ($content | Select-String -Pattern "ScreenSaveActive = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        $isScreensaverEnabled = ($screenSaveActive -eq 1)
        $isTimeoutGood = ($screenSaverTimeout -le $maxIdleTimeSeconds)
        $isPasswordProtected = ($screenSaverIsSecure -eq 1)

        if (-not $isScreensaverEnabled) {
            $result = "Vulnerable"
            $details += "Screensaver is not enabled. "
        }
        if (-not $isTimeoutGood) {
            $result = "Vulnerable"
            $details += "Screensaver timeout ($($screenSaverTimeout/60) minutes) is greater than recommended 10 minutes. "
        }
        if (-not $isPasswordProtected) {
            $result = "Vulnerable"
            $details += "Screensaver is not password protected. "
        }

        if ($result -eq "Good") {
            $details = "Screensaver is enabled, set to $($screenSaverTimeout/60) minutes, and password protected."
        } elseif ($details.Count -gt 0) {
            $details = "Screensaver settings are vulnerable: " + ($details -join '')
        } else {
            $result = "Error"
            $details = "Could not retrieve all screensaver policy settings."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking screensaver settings: $($_.Exception.Message)"
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
Test-W38ScreensaverSetting

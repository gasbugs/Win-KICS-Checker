<#
.SYNOPSIS
    Checks the Account Lockout Duration and Reset Account Lockout Counter After policies.

.DESCRIPTION
    This script verifies if the 'Account lockout duration' and 'Reset account lockout counter after'
    policies are configured to 60 minutes (3600 seconds) or more, as recommended for security.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W47AccountLockoutDurationSetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-47"
    $category = "Account Management"
    $result = "Good"
    $details = ""
    $minRecommendedSeconds = 3600 # 60 minutes

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $lockoutDuration = ($content | Select-String -Pattern "LockoutDuration = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $resetLockoutCount = ($content | Select-String -Pattern "ResetLockoutCount = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        $isLockoutDurationGood = $lockoutDuration -ge $minRecommendedSeconds
        $isResetLockoutCountGood = $resetLockoutCount -ge $minRecommendedSeconds

        if ($isLockoutDurationGood -and $isResetLockoutCountGood) {
            $details = "Account lockout duration ($($lockoutDuration/60) minutes) and Reset account lockout counter after ($($resetLockoutCount/60) minutes) are set to recommended values (>= 60 minutes)."
        } else {
            $result = "Vulnerable"
            $details = "Account lockout duration ($($lockoutDuration/60) minutes) or Reset account lockout counter after ($($resetLockoutCount/60) minutes) are not set to recommended values (>= 60 minutes)."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking account lockout policies: $($_.Exception.Message)"
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
Test-W47AccountLockoutDurationSetting

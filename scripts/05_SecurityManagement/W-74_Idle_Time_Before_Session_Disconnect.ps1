<#
.SYNOPSIS
    Checks if the 'Microsoft network server: Disconnect clients when logon hours expire' and 'Microsoft network server: Amount of idle time required before suspending session' policies are configured.

.DESCRIPTION
    This script verifies two security policies related to network session management.
    It ensures that clients are disconnected when logon hours expire and that idle sessions are suspended after 15 minutes,
    to prevent unauthorized access and resource exhaustion.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W74IdleTimeBeforeSessionDisconnect {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-74"
    $category = "Security Management"
    $result = "Good"
    $details = @()
    $recommendedIdleTimeSeconds = 900 # 15 minutes

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $disconnectClientsOnLogonHoursExpire = ($content | Select-String -Pattern "DisconnectClientsOnLogonHoursExpire = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $autoDisconnect = ($content | Select-String -Pattern "AutoDisconnect = " | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        $isDisconnectClientsGood = ($disconnectClientsOnLogonHoursExpire -eq 1)
        $isAutoDisconnectGood = ($autoDisconnect -eq $recommendedIdleTimeSeconds)

        if (-not $isDisconnectClientsGood) {
            $result = "Vulnerable"
            $details += "'Microsoft network server: Disconnect clients when logon hours expire' policy is not enabled (Current: $disconnectClientsOnLogonHoursExpire). "
        }
        if (-not $isAutoDisconnectGood) {
            $result = "Vulnerable"
            $details += "'Microsoft network server: Amount of idle time required before suspending session' policy is not set to $recommendedIdleTimeSeconds seconds (Current: $autoDisconnect seconds). "
        }

        if ($result -eq "Good") {
            $details = "Both session management policies are configured as recommended."
        } elseif ($details.Count -gt 0) {
            $details = "Session management policies are vulnerable: " + ($details -join [Environment]::NewLine)
        } else {
            $result = "Error"
            $details = "Could not retrieve all session management policy settings."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking session management policies: $($_.Exception.Message)"
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
Test-W74IdleTimeBeforeSessionDisconnect

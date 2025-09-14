<#
.SYNOPSIS
    Checks if the remote terminal connection timeout (idle session limit) is configured.

.DESCRIPTION
    This script verifies if the 'MaxIdleTime' for RDP sessions is set to a reasonable value,
    such as 30 minutes (1,800,000 milliseconds) or less, to prevent unauthorized access during idle periods.
    A value of 0 means sessions never disconnect due to inactivity, which is vulnerable.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W67RemoteTerminalConnectionTimeout {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-67"
    $category = "Service Management"
    $result = "Good"
    $details = ""
    $maxRecommendedIdleTimeMs = 1800000 # 30 minutes in milliseconds

    try {
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $propertyName = "MaxIdleTime"
        
        if (Test-Path $registryPath) {
            $maxIdleTime = (Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue).$propertyName

            if ($null -eq $maxIdleTime) {
                $result = "Vulnerable"
                $details = "'MaxIdleTime' registry value not found at '$registryPath'. Idle sessions might not be disconnected."
            } elseif ($maxIdleTime -eq 0) {
                $result = "Vulnerable"
                $details = "Remote terminal connection timeout (MaxIdleTime) is set to 0 (never disconnect)."
            } elseif ($maxIdleTime -le $maxRecommendedIdleTimeMs) {
                $details = "Remote terminal connection timeout (MaxIdleTime) is set to $($maxIdleTime / 60000) minutes (Recommended: <= 30 minutes)."
            } else {
                $result = "Vulnerable"
                $details = "Remote terminal connection timeout (MaxIdleTime) is set to $($maxIdleTime / 60000) minutes, which is greater than the recommended 30 minutes."
            }
        } else {
            $result = "Error"
            $details = "Registry path '$registryPath' not found. Terminal Services might not be installed or configured."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking remote terminal connection timeout: $($_.Exception.Message)"
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
Test-W67RemoteTerminalConnectionTimeout

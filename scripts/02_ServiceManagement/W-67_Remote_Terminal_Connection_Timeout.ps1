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
        $termService = Get-Service -Name TermService -ErrorAction SilentlyContinue

        if (-not $termService -or $termService.Status -ne 'Running') {
            $details = "Remote Desktop Services (TermService) is not running or not installed. (Good)"
        } else {
            $propertyName = "MaxIdleTime"
            $idleTime = $null

            # 1. Check Group Policy (GPO) path first
            $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
            if (Test-Path $policyPath) {
                $idleTime = (Get-ItemProperty -Path $policyPath -Name $propertyName -ErrorAction SilentlyContinue).$propertyName
            }

            # 2. If no value from policy, check RDP direct setting path
            if ($null -eq $idleTime) {
                $rdpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
                if (Test-Path $rdpPath) {
                    $idleTime = (Get-ItemProperty -Path $rdpPath -Name $propertyName -ErrorAction SilentlyContinue).$propertyName
                }
            }

            if ($null -eq $idleTime) {
                $result = "Vulnerable"
                $details = "Remote terminal connection timeout (MaxIdleTime) is not configured. Idle sessions might not be disconnected."
            } elseif ($idleTime -eq 0) {
                $result = "Vulnerable"
                $details = "Remote terminal connection timeout (MaxIdleTime) is set to 0 (never disconnect)."
            } elseif ($idleTime -le $maxRecommendedIdleTimeMs) {
                $details = "Remote terminal connection timeout (MaxIdleTime) is set to $($idleTime / 60000) minutes (Recommended: <= 30 minutes)."
            } else {
                $result = "Vulnerable"
                $details = "Remote terminal connection timeout (MaxIdleTime) is set to $($idleTime / 60000) minutes, which is greater than the recommended 30 minutes."
            }
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
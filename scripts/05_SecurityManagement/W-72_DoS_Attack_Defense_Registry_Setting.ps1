<#
.SYNOPSIS
    Checks if DoS attack defense registry values are set as recommended.

.DESCRIPTION
    This script verifies several registry settings related to TCP/IP stack hardening
    to defend against Denial-of-Service (DoS) attacks.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W72DoSAttackDefenseRegistrySetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-72"
    $category = "Security Management"
    $result = "Good"
    $details = @()

    $registryPath = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters"

    try {
        if (Test-Path $registryPath) {
            # SynAttackProtect
            $synAttackProtect = (Get-ItemProperty -Path $registryPath -Name "SynAttackProtect" -ErrorAction SilentlyContinue).SynAttackProtect
            if ($null -eq $synAttackProtect -or ($synAttackProtect -ne 1 -and $synAttackProtect -ne 2)) {
                $result = "Vulnerable"
                $details += "SynAttackProtect is not set to 1 or 2 (Current: $($synAttackProtect -replace '^$', 'Not Set')). "
            } else {
                $details += "SynAttackProtect is set to $synAttackProtect. "
            }

            # EnableDeadGWDetect
            $enableDeadGWDetect = (Get-ItemProperty -Path $registryPath -Name "EnableDeadGWDetect" -ErrorAction SilentlyContinue).EnableDeadGWDetect
            if ($null -eq $enableDeadGWDetect -or $enableDeadGWDetect -ne 0) {
                $result = "Vulnerable"
                $details += "EnableDeadGWDetect is not set to 0 (Current: $($enableDeadGWDetect -replace '^$', 'Not Set')). "
            } else {
                $details += "EnableDeadGWDetect is set to $enableDeadGWDetect. "
            }

            # KeepAliveTime (5 minutes = 300000 milliseconds)
            $keepAliveTime = (Get-ItemProperty -Path $registryPath -Name "KeepAliveTime" -ErrorAction SilentlyContinue).KeepAliveTime
            $recommendedKeepAliveTime = 300000
            if ($null -eq $keepAliveTime -or $keepAliveTime -ne $recommendedKeepAliveTime) {
                $result = "Vulnerable"
                $details += "KeepAliveTime is not set to $recommendedKeepAliveTime (5 minutes) (Current: $($keepAliveTime -replace '^$', 'Not Set') milliseconds). "
            } else {
                $details += "KeepAliveTime is set to $keepAliveTime milliseconds. "
            }

            # NoNameReleaseOnDemand
            $noNameReleaseOnDemand = (Get-ItemProperty -Path $registryPath -Name "NoNameReleaseOnDemand" -ErrorAction SilentlyContinue).NoNameReleaseOnDemand
            if ($null -eq $noNameReleaseOnDemand -or $noNameReleaseOnDemand -ne 1) {
                $result = "Vulnerable"
                $details += "NoNameReleaseOnDemand is not set to 1 (Current: $($noNameReleaseOnDemand -replace '^$', 'Not Set')). "
            } else {
                $details += "NoNameReleaseOnDemand is set to $noNameReleaseOnDemand. "
            }

            if ($details.Count -eq 0) {
                $details = "All DoS defense registry settings are configured as recommended."
            } else {
                $details = "Some DoS defense registry settings are not configured as recommended: " + ($details -join [Environment]::NewLine)
            }
        } else {
            $result = "Error"
            $details = "Registry path '$registryPath' not found. Cannot check DoS defense settings."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking DoS defense registry settings: $($_.Exception.Message)"
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
Test-W72DoSAttackDefenseRegistrySetting

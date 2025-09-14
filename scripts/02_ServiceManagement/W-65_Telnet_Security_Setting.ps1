<#
.SYNOPSIS
    Checks if the Telnet service is disabled or if its authentication method is NTLM.

.DESCRIPTION
    This script verifies the status of the Telnet service.
    If the service is running, it indicates that its authentication method requires manual verification
    as programmatic checking of Telnet configuration can be complex.
    If the service is not running, it is considered good.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W65TelnetSecuritySetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-65"
    $category = "Service Management"
    $result = "Good"
    $details = ""

    try {
        $telnetService = Get-Service -Name TlntSvr -ErrorAction SilentlyContinue

        if (-not $telnetService) {
            $details = "Telnet service is not installed. (Good)"
        } elseif ($telnetService.Status -eq 'Running') {
            $result = "Manual Check Required"
            $details = "Telnet service is running. Authentication method (NTLM vs. Password) requires manual verification (tlntadmn config)."
        } else {
            $details = "Telnet service is installed but not running. (Good)"
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking Telnet service status: $($_.Exception.Message)"
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
Test-W65TelnetSecuritySetting

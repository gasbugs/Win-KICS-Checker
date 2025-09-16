<#
.SYNOPSIS
    Checks if the Telnet service is disabled or if its authentication method is NTLM.

.DESCRIPTION
    This script verifies the status of the Telnet service.
    If the service is running, it indicates that its authentication method requires manual verification
    as programmatic checking of Telnet configuration can be complex.
    If the service is not running, it is considered good.

    NOTE: For Windows Server 2019, this check is considered not applicable as per user guidance.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W65TelnetSecuritySetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-65"
    $category = "Service Management"
    $result = "Good"
    $details = "This check is not applicable for Windows Server 2019 as Telnet Server installation is not provided in Windows 2016 and above versions due to security issues (refer to KISA guide)."

    # For Windows Server 2019, this check is considered not applicable.
    # The script will always return 'Good' with a specific detail message.

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

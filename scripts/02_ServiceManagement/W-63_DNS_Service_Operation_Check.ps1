<#
.SYNOPSIS
    Checks if the DNS Server service is running and if dynamic updates are disabled.

.DESCRIPTION
    This script verifies the status of the DNS Server service.
    According to the guideline, if the DNS service is not used or dynamic updates are disabled, it is considered good.
    If the DNS Server service is running, it indicates that dynamic update settings require manual verification
    due to the complexity of checking all DNS zones and their configurations.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W63DNSServiceOperationCheck {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-63"
    $category = "Service Management"
    $result = "Good"
    $details = ""

    try {
        $dnsService = Get-Service -Name "DNS" -ErrorAction SilentlyContinue

        if (-not $dnsService) {
            $details = "DNS Server service is not installed. (Good)"
        } elseif ($dnsService.Status -eq 'Running') {
            $result = "Manual Check Required"
            $details = "DNS Server service is running. Dynamic update settings for each zone require manual verification (DNSMGMT.MSC)."
        } else {
            $details = "DNS Server service is installed but not running. (Good)"
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking DNS service status: $($_.Exception.Message)"
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
Test-W63DNSServiceOperationCheck

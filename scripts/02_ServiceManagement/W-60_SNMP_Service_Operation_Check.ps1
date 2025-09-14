<#
.SYNOPSIS
    Checks if the SNMP service is running.

.DESCRIPTION
    This script verifies the status of the SNMP service.
    According to the guideline, if the SNMP service is running, it is considered vulnerable.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W60SNMPServiceOperationCheck {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-60"
    $category = "Service Management"
    $result = "Good"
    $details = ""

    try {
        $snmpService = Get-Service -Name SNMP -ErrorAction SilentlyContinue

        if (-not $snmpService) {
            $details = "SNMP service is not installed. (Good)"
        } elseif ($snmpService.Status -eq 'Running') {
            $result = "Vulnerable"
            $details = "SNMP service is running."
        } else {
            $details = "SNMP service is installed but not running. (Good)"
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking SNMP service status: $($_.Exception.Message)"
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
Test-W60SNMPServiceOperationCheck

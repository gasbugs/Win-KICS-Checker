<#
.SYNOPSIS
    Checks if the Remote Registry Service is disabled.

.DESCRIPTION
    This script verifies the status of the Remote Registry Service.
    According to the guideline, if the Remote Registry Service is stopped, it is considered good,
    as it prevents unauthorized remote access to the system's registry.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W35RemotelyAccessibleRegistryPaths {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-35"
    $category = "Log Management"
    $result = "Good"
    $details = ""

    try {
        $remoteRegistryService = Get-Service -Name RemoteRegistry -ErrorAction SilentlyContinue

        if (-not $remoteRegistryService) {
            $details = "Remote Registry Service is not installed. (Good)"
        } elseif ($remoteRegistryService.Status -eq 'Stopped') {
            $details = "Remote Registry Service is stopped. (Good)"
        } else {
            $result = "Vulnerable"
            $details = "Remote Registry Service is running."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking Remote Registry Service status: $($_.Exception.Message)"
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
Test-W35RemotelyAccessibleRegistryPaths

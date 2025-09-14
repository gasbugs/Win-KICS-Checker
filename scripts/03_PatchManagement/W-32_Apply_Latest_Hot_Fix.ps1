<#
.SYNOPSIS
    Checks if the latest Hot Fixes are applied.

.DESCRIPTION
    This script checks the status of the Windows Update service.
    Programmatically verifying the application of the 'latest' hotfixes is complex and typically requires
    access to external update catalogs or a Patch Management System (PMS).
    Therefore, this check reports the status of the Windows Update service and indicates that manual review
    of the system's patch status is required.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W32ApplyLatestHotFix {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-32"
    $category = "Patch Management"
    $result = "Manual Check Required"
    $details = ""

    try {
        $windowsUpdateService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue

        if (-not $windowsUpdateService) {
            $details = "Windows Update service (wuauserv) is not installed. Manual review of patch status is required."
        } elseif ($windowsUpdateService.Status -eq 'Running') {
            $details = "Windows Update service (wuauserv) is running. Manual review of system patch status is required to ensure latest hotfixes are applied."
        } else {
            $details = "Windows Update service (wuauserv) is installed but not running. Manual review of system patch status is required to ensure latest hotfixes are applied."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking Windows Update service status: $($_.Exception.Message)"
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
Test-W32ApplyLatestHotFix

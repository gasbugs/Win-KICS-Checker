<#
.SYNOPSIS
    Checks if the antivirus program is up-to-date.

.DESCRIPTION
    This script checks the status of the Windows Defender Antivirus Service.
    Programmatically verifying the update status of all possible antivirus solutions is highly complex.
    Therefore, this check focuses on the built-in Windows Defender and indicates that manual review
    of other installed antivirus programs (if any) is required.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W33AntivirusProgramUpdate {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-33"
    $category = "Patch Management"
    $result = "Manual Check Required"
    $details = ""

    try {
        $defenderService = Get-Service -Name WinDefend -ErrorAction SilentlyContinue

        if (-not $defenderService) {
            $details = "Windows Defender Antivirus Service is not installed. Manual review of antivirus solution status is required."
        } elseif ($defenderService.Status -eq 'Running') {
            $details = "Windows Defender Antivirus Service is running. Manual review of its update status and other installed antivirus solutions is required."
        } else {
            $details = "Windows Defender Antivirus Service is installed but not running. Manual review of its update status and other installed antivirus solutions is required."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking antivirus program status: $($_.Exception.Message)"
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
Test-W33AntivirusProgramUpdate

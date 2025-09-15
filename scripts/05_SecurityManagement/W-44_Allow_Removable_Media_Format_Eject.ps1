<#
.SYNOPSIS
    Checks if the 'Devices: Allow users to format and eject removable media' policy is restricted to Administrators.

.DESCRIPTION
    This script verifies the 'Devices: Allow users to format and eject removable media' user rights assignment.
    It ensures that only the 'Administrators' group is granted this right, preventing unauthorized formatting or ejection of removable media.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including assigned users/groups.
#>

function Test-W44AllowRemovableMediaFormatEject {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-44"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $allocateDASDValue = $null
        try {
            $regValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "allocateDASD" -ErrorAction Stop
            $allocateDASDValue = $regValue.allocateDASD
        } catch {
            # If the registry value is not found, it defaults to 1 (all users can allocate)
            $allocateDASDValue = 1
        }

        if ($allocateDASDValue -eq 0) {
            $result = "Good"
            $details = "Only Administrators are allowed to format and eject removable media (allocateDASD is 0)."
        } else {
            $result = "Vulnerable"
            $details = "All users are allowed to format and eject removable media (allocateDASD is $allocateDASDValue). Recommended: 0 (Administrators only)."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking removable media format/eject policy: $($_.Exception.Message)"
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
Test-W44AllowRemovableMediaFormatEject

<#
.SYNOPSIS
    Checks if NTFS file system is used for all local drives.

.DESCRIPTION
    This script verifies that all local fixed drives are formatted with the NTFS file system.
    NTFS provides enhanced security features like access control lists (ACLs) compared to FAT file systems.
    It uses Get-WmiObject Win32_LogicalDisk to check drive types and file systems for broader compatibility.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W79FileDirectoryProtection {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-79"
    $category = "Security Management"
    $result = "Good"
    $details = @()

    try {
        # DriveType 3 indicates a local disk
        $logicalDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 3" -ErrorAction SilentlyContinue

        if ($logicalDisks) {
            $nonNtfsVolumes = @()
            foreach ($disk in $logicalDisks) {
                if ($disk.FileSystem -ne 'NTFS') {
                    $nonNtfsVolumes += "Drive $($disk.DeviceID) has file system $($disk.FileSystem)."
                }
            }

            if ($nonNtfsVolumes.Count -eq 0) {
                $details = "All fixed drives are using the NTFS file system."
            } else {
                $result = "Vulnerable"
                $details = "The following fixed drives are not using the NTFS file system: " + ($nonNtfsVolumes -join [Environment]::NewLine)
            }
        } else {
            $details = "No fixed drives found to check. (Good)"
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking file system types: $($_.Exception.Message)"
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
Test-W79FileDirectoryProtection
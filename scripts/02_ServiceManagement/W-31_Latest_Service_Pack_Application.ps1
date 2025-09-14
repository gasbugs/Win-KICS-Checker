<#
.SYNOPSIS
    Checks if the latest service pack is applied to the operating system.

.DESCRIPTION
    This script checks the operating system version and service pack information.
    For Windows Server 2016/2019 and newer, it considers the system "Good" as these versions
    typically do not use traditional service packs. For older OS versions, it checks
    if a service pack is installed.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W31LatestServicePackApplication {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-31"
    $category = "Service Management"
    $result = "Good"
    $details = ""

    try {
        $os = Get-WmiObject Win32_OperatingSystem

        $osCaption = $os.Caption
        $servicePackMajorVersion = $os.ServicePackMajorVersion
        $osVersion = [Version]$os.Version

        # Windows Server 2016 (10.0.14393) and 2019 (10.0.17763) and newer typically don't have traditional service packs.
        # For simplicity, we'll check major version 10.0 (Windows 10/Server 2016+)
        if ($osVersion.Major -ge 10) {
            $details = "Operating system ($osCaption) is a newer version (Windows Server 2016/2019 or later) which typically does not use traditional service packs. Regular updates are expected."
        }
        # For older OS versions, check for service pack presence
        elseif ($servicePackMajorVersion -eq 0) {
            $result = "Vulnerable"
            $details = "Operating system ($osCaption) is missing a service pack. Current Service Pack Major Version: $servicePackMajorVersion."
        }
        else {
            $details = "Operating system ($osCaption) has Service Pack $servicePackMajorVersion installed."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking service pack: $($_.Exception.Message)"
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
Test-W31LatestServicePackApplication

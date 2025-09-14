<#
.SYNOPSIS
    Checks if an antivirus program is installed on the system.

.DESCRIPTION
    This script queries the Windows Security Center (SecurityCenter2 WMI class)
    to detect the presence of an installed and active antivirus product.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W36AntivirusProgramInstallation {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-36"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $antivirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class "AntivirusProduct" -ErrorAction SilentlyContinue

        if ($antivirusProducts -and $antivirusProducts.Count -gt 0) {
            $installedAVs = @($antivirusProducts | Select-Object -ExpandProperty displayName)
            $details = "Antivirus program(s) installed: $($installedAVs -join ', ')."
        } else {
            $result = "Vulnerable"
            $details = "No active antivirus program detected by Windows Security Center."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking for antivirus program installation: $($_.Exception.Message)"
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
Test-W36AntivirusProgramInstallation

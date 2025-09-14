<#
.SYNOPSIS
    Checks for the presence of unnecessary ODBC/OLE-DB data sources.

.DESCRIPTION
    This script lists the System DSNs (Data Source Names) configured on the system.
    Determining if a DSN is 'in use' programmatically is challenging without application-specific knowledge.
    Therefore, this check reports all System DSNs and requires manual review to identify and remove unnecessary ones.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including a list of System DSNs.
#>

function Test-W66RemoveUnnecessaryODBCOLEDB {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-66"
    $category = "Service Management"
    $result = "Manual Check Required"
    $details = "Review the list of System DSNs to identify and remove any unnecessary data sources."
    $systemDsns = @()

    try {
        # Get System DSNs from registry
        $registryPath = "HKLM:\SOFTWARE\ODBC\ODBC.INI"
        if (Test-Path $registryPath) {
            $dsnNames = (Get-Item -Path $registryPath).GetSubKeyNames() | Where-Object { $_ -ne "ODBC Data Sources" }

            foreach ($dsnName in $dsnNames) {
                $dsnPath = Join-Path $registryPath $dsnName
                $driver = (Get-ItemProperty -Path $dsnPath -Name "Driver" -ErrorAction SilentlyContinue).Driver
                $description = (Get-ItemProperty -Path $dsnPath -Name "Description" -ErrorAction SilentlyContinue).Description
                $server = (Get-ItemProperty -Path $dsnPath -Name "Server" -ErrorAction SilentlyContinue).Server

                $systemDsns += @{
                    Name = $dsnName
                    Driver = $driver
                    Description = $description
                    Server = $server
                }
            }
        }

        if ($systemDsns.Count -eq 0) {
            $details = "No System DSNs found. (Good)"
            $result = "Good"
        } else {
            $details = "The following System DSNs were found. Manual review is required to identify and remove any unnecessary data sources.`n" + ($systemDsns | Out-String)
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking ODBC/OLE-DB data sources: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        SystemDSNs = $systemDsns # Include DSN details for manual review
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W66RemoveUnnecessaryODBCOLEDB

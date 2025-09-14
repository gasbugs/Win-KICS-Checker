<#
.SYNOPSIS
    Checks if SQL Server is using Windows Authentication Mode and if the 'sa' account is disabled.

.DESCRIPTION
    This script verifies the authentication mode of SQL Server instances.
    It recommends using Windows Authentication Mode and disabling the 'sa' account for enhanced security.
    If Mixed Mode is used, it advises ensuring the 'sa' account has a strong password.
    Due to the complexity of programmatic SQL Server configuration checks, this script primarily checks
    if the SQL Server service is running and advises manual verification of its authentication settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W82UseWindowsAuthenticationMode {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-82"
    $category = "Security Management"
    $result = "Manual Check Required"
    $details = ""

    try {
        # Common SQL Server service names
        $sqlServiceNames = @("MSSQLSERVER", "MSSQL$SQLEXPRESS")
        $sqlServiceRunning = $false

        foreach ($serviceName in $sqlServiceNames) {
            $sqlService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($sqlService -and $sqlService.Status -eq 'Running') {
                $sqlServiceRunning = $true
                break
            }
        }

        if ($sqlServiceRunning) {
            $details = "SQL Server service is running. Manual verification is required to ensure it uses Windows Authentication Mode and that the 'sa' account is disabled or has a strong password (refer to SQL Server Management Studio -> Server Properties -> Security)."
        } else {
            $details = "SQL Server service is not running or not installed. This check is not applicable."
            $result = "Good"
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking SQL Server authentication mode: $($_.Exception.Message)"
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
Test-W82UseWindowsAuthenticationMode

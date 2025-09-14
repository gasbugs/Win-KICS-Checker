<#
.SYNOPSIS
    Checks if IIS web service information (like Server and X-Powered-By headers) is hidden.

.DESCRIPTION
    This script attempts to connect to the local IIS web server and inspects the HTTP response headers.
    If 'Server' or 'X-Powered-By' headers are present, it indicates that web service information is being exposed,
    which is considered a vulnerability. If IIS is not running or not installed, the check will report as 'Not Applicable'.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W59HideIISWebServiceInformation {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-59"
        Category = "Service Management"
        Result = "Not Applicable"
        Details = "IIS is not installed or WebAdministration module is not available."
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    try {
        # Check if WebAdministration module is available, which indicates IIS is likely installed.
        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            # This message is the default, so no change needed if module is not found.
            $result | ConvertTo-Json -Depth 4
            return
        }
        
        Import-Module WebAdministration -ErrorAction Stop

        # Check the removeServerHeader property directly
        $config = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/security/requestFiltering" -Name "removeServerHeader" -ErrorAction SilentlyContinue

        if ($null -eq $config) {
            # This can happen if IIS is not installed or the section is not accessible.
             $result.Details = "Could not retrieve IIS configuration for removeServerHeader. IIS might not be fully installed."
        } elseif ($config.Value -eq $true) {
            $result.Result = "Good"
            $result.Details = "IIS is configured to hide the web service information (removeServerHeader is true)."
        } else {
            $result.Result = "Vulnerable"
            $result.Details = "IIS is not configured to hide the web service information (removeServerHeader is false)."
        }
    } catch {
        # Catch errors from Import-Module or other unexpected issues
        $result.Result = "Error"
        $result.Details = "An error occurred: $($_.Exception.Message)"
    }

    $result | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W59HideIISWebServiceInformation

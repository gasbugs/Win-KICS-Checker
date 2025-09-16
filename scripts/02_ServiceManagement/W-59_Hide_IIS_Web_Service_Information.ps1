<#
.SYNOPSIS
    Checks the IIS HTTP error mode to ensure custom error pages are used.

.DESCRIPTION
    This script checks the 'errorMode' property within the 'system.webServer/httpErrors' configuration section.
    The recommended setting is 'Custom' to avoid leaking sensitive information through detailed or default error pages.
    Any other setting (e.g., 'DetailedLocalOnly', 'Detailed') is considered a vulnerability.

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
            $result | ConvertTo-Json -Depth 4
            return
        }
        
        Import-Module WebAdministration -ErrorAction Stop

        # Check the errorMode property
        $config = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/httpErrors" -Name "errorMode" -ErrorAction SilentlyContinue

        if ($null -eq $config) {
            $result.Details = "Could not retrieve IIS configuration for httpErrors/errorMode. IIS might not be fully installed."
        } else {
            $errorMode = $config
            if ($errorMode -eq 'Custom') {
                $result.Result = "Good"
                $result.Details = "IIS is configured with custom error pages (errorMode is 'Custom')."
            } else {
                $result.Result = "Vulnerable"
                $result.Details = "IIS errorMode is set to '$errorMode'. It is recommended to use 'Custom' to avoid leaking information."
            }
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

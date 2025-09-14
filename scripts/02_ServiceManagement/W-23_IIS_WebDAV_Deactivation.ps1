# W-23_IIS_WebDAV_Deactivation.ps1
# Checks whether WebDAV is disabled.

function Test-IISWebDAVDeactivation {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-23"
        Category = "Service Management"
        Result = "Not Applicable"
        Details = "IIS WebAdministration module not found. This check is not applicable."
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        return $result
    }

    try {
        Import-Module WebAdministration -ErrorAction Stop
        $webDavModule = Get-WebGlobalModule -Name "WebDAVModule" -ErrorAction SilentlyContinue
        if ($webDavModule) {
            $result.Result = "Vulnerable"
            $result.Details = "WebDAV module is enabled in IIS. It should be disabled if not in use."
        } else {
            $result.Result = "Good"
            $result.Details = "WebDAV module is not enabled in IIS."
        }
    } catch {
        $result.Result = "Error"
        $result.Details = "An error occurred while checking WebDAV status: $($_.Exception.Message)"
    }

    return $result
}

Test-IISWebDAVDeactivation | ConvertTo-Json -Depth 100
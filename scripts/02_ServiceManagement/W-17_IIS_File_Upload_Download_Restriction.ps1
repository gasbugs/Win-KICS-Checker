# W-17: IIS File Upload and Download Restriction
# Checks if file upload and download sizes are restricted in IIS.
# Due to the complexity and context-dependency, this check requires manual verification.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-17'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'IIS is not installed, so this check is not applicable.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

try {
    # Check if the WebAdministration module is available (indicates IIS is likely installed)
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        $result.Details = "IIS is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
        # Result remains 'Good'
    } else {
        Import-Module WebAdministration -ErrorAction Stop

        $result.Result = 'Manual Check Required'
        $result.Details = "IIS is installed. File upload and download size restrictions (W-17) require manual verification due to their context-dependent nature and the need to inspect application-specific configurations."
        $result.Details += "\n\nManual Check Steps (refer to guide for details):
1. Inspect 'applicationHost.config' (typically %SystemRoot%\System32\inetsrv\config\applicationHost.config) for global settings like 'maxAllowedContentLength'.
2. Inspect 'web.config' files in website root directories for site-specific settings like 'maxAllowedContentLength', 'MaxRequestEntityAllowed', and 'bufferingLimit'.
3. Verify if the web application actually uses file upload/download features and if the configured limits are appropriate for the system's role.
Default values (if not explicitly set) are: maxAllowedContentLength (30MB), MaxRequestEntityAllowed (200000 bytes), bufferingLimit (4MB)."
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while preparing the IIS file upload/download restriction check: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Compress

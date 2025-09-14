# W-10: IIS Service Operation Check
# Checks if the World Wide Web Publishing Service (W3SVC) is running.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-10'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'The World Wide Web Publishing Service (W3SVC) is not running or not installed.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

try {
    $serviceName = "W3SVC"
    $iisService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($iisService -and $iisService.Status -eq 'Running') {
        $result.Result = 'Vulnerable'
        $result.Details = "The World Wide Web Publishing Service (W3SVC) is running. If this service is not required, it should be disabled."
    }
    # If service is not found or stopped, the default 'Good' result is appropriate.

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking the W3SVC service: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Compress

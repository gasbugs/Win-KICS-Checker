# W-25_FTP_Service_Operation_Check.ps1
# Checks whether any process is listening on the standard FTP port (21).

function Test-FTPServiceOperationCheck {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-25"
        Category = "Service Management"
        Result = "Good"
        Details = "No active FTP service found."
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    try {
        # Check for IIS FTP Service first
        $ftpService = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
        if ($ftpService -and $ftpService.Status -eq "Running") {
            $result.Result = "Vulnerable"
            $result.Details = "Standard IIS FTP service (FTPSVC) is running. It should be disabled if not in use or replaced with a secure alternative (SFTP/FTPS)."
            return $result
        }

        # Check for any process listening on port 21
        $tcpConnections = Get-NetTCPConnection -LocalPort 21 -State Listen -ErrorAction SilentlyContinue
        if ($tcpConnections) {
            $processId = $tcpConnections[0].OwningProcess
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "N/A" }
            
            $result.Result = "Vulnerable"
            $result.Details = "A process is listening on the standard FTP port (21). Process Name: '$processName' (PID: $processId). If this is an FTP service, ensure it is secure (SFTP/FTPS) or disable it if not needed."
        } else {
            $result.Result = "Good"
            $result.Details = "No service or process found listening on the standard FTP port (21)."
        }
    } catch {
        $result.Result = "Error"
        $result.Details = "An error occurred while checking for FTP services: $($_.Exception.Message)"
    }

    return $result
}

Test-FTPServiceOperationCheck | ConvertTo-Json -Depth 100
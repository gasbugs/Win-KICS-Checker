# W-28_FTP_Access_Control_Setting.ps1
function Test-FTPAccessControlSetting {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-28"
        Category = "Service Management"
        Result = "Not Applicable"
        Details = "FTP Service (FTPSVC) not found or not running."
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    $ftpService = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if (-not $ftpService -or $ftpService.Status -ne 'Running') {
        return $result
    }

    $appHostConfigPath = "$env:windir\System32\inetsrv\config\applicationHost.config"
    if (-not (Test-Path $appHostConfigPath)) {
        $result.Result = "Manual Check Required"
        $result.Details = "applicationHost.config not found. FTP configuration could not be verified automatically."
        return $result
    }

    try {
        [xml]$appHostConfig = Get-Content $appHostConfigPath

        $ftpSites = $appHostConfig.configuration.'system.applicationHost'.sites.site | Where-Object { $_.bindings.binding.protocol -eq 'ftp' }

        if (-not $ftpSites) {
            $result.Result = "Good"
            $result.Details = "FTP service is running, but no FTP sites are configured."
            return $result
        }

        $vulnerableSites = @()
        foreach ($site in $ftpSites) {
            $ipSecurity = $site.ftpServer.security.ipSecurity
            if ($ipSecurity -and $ipSecurity.allowUnlisted -ne 'false') {
                # Vulnerable if allowUnlisted is not explicitly false
                $vulnerableSites += $site.name
            } elseif (-not $ipSecurity) {
                # Vulnerable if the ipSecurity section doesn't exist, as default is allow
                $vulnerableSites += $site.name
            }
        }

        if ($vulnerableSites.Count -gt 0) {
            $result.Result = "Vulnerable"
            $result.Details = "FTP access on the following sites is not restricted by IP address (default is allow): $($vulnerableSites -join ', ')."
        } else {
            $result.Result = "Good"
            $result.Details = "All checked FTP sites have IP restrictions configured."
        }
    } catch {
        $result.Result = "Error"
        $result.Details = "Failed to parse applicationHost.config: $($_.Exception.Message)"
    }

    return $result
}

Test-FTPAccessControlSetting | ConvertTo-Json -Depth 100
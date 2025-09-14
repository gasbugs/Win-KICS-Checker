# W-27_Anonymous_FTP_Prohibition.ps1
function Test-AnonymousFTPProhibition {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-27"
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
            $anonymousAuth = $site.ftpServer.security.authentication.anonymousAuthentication
            if ($anonymousAuth -and $anonymousAuth.enabled -eq 'true') {
                $vulnerableSites += $site.name
            }
        }

        if ($vulnerableSites.Count -gt 0) {
            $result.Result = "Vulnerable"
            $result.Details = "Anonymous FTP access is enabled on the following sites: $($vulnerableSites -join ', ')."
        } else {
            $result.Result = "Good"
            $result.Details = "Anonymous FTP access is disabled on all checked FTP sites."
        }
    } catch {
        $result.Result = "Error"
        $result.Details = "Failed to parse applicationHost.config: $($_.Exception.Message)"
    }

    return $result
}

Test-AnonymousFTPProhibition | ConvertTo-Json -Depth 100
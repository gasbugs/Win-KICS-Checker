# W-23: 공유 서비스에 대한 익명 접근 제한 설정
function Test-W23 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-23"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $ftpsvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
        if (-not $ftpsvc -or $ftpsvc.Status -ne 'Running') {
            $result.Result  = "Not Applicable"
            $result.Details = "FTP service is not running."
            $result | ConvertTo-Json -Depth 4
            return
        }

        $appHostConfig = "$env:SystemRoot\System32\inetsrv\config\applicationHost.config"
        if (-not (Test-Path $appHostConfig)) {
            $result.Result  = "Error"
            $result.Details = "applicationHost.config not found."
            $result | ConvertTo-Json -Depth 4
            return
        }

        [xml]$config = Get-Content $appHostConfig
        $ftpSites = $config.configuration.'system.applicationHost'.sites.site |
            Where-Object { $_.ftpServer }
        $vulnerableSites = @()

        foreach ($site in $ftpSites) {
            $anonAuth = $site.ftpServer.security.authentication.anonymousAuthentication
            if ($anonAuth -and $anonAuth.enabled -eq 'true') {
                $vulnerableSites += $site.name
            }
        }

        if ($vulnerableSites.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Anonymous FTP authentication is enabled on: $($vulnerableSites -join ', ')"
        } else {
            $result.Details = "Anonymous FTP authentication is disabled on all FTP sites."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking anonymous FTP: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W23

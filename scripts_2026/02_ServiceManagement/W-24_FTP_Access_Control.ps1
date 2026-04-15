# W-24: FTP 접근 제어 설정
function Test-W24 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-24"
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
            $ipSecurity = $site.ftpServer.security.ipSecurity
            if (-not $ipSecurity -or $ipSecurity.allowUnlisted -ne 'false') {
                $vulnerableSites += $site.name
            }
        }

        if ($vulnerableSites.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "FTP IP access control not restricted on: $($vulnerableSites -join ', ')"
        } else {
            $result.Details = "FTP IP access control is properly configured on all FTP sites."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking FTP access control: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W24

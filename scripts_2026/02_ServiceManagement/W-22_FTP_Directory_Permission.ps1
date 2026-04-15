# W-22: FTP 디렉토리 접근권한 설정
function Test-W22 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-22"
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
        $vulnerableDirs = @()

        foreach ($site in $ftpSites) {
            $physicalPath = $site.application.virtualDirectory.physicalPath
            if ($physicalPath -and (Test-Path $physicalPath)) {
                $acl = Get-Acl $physicalPath
                foreach ($ace in $acl.Access) {
                    if ($ace.IdentityReference.Value -eq 'Everyone' -and
                        $ace.FileSystemRights -match 'Write|Modify|FullControl') {
                        $vulnerableDirs += "$($site.name): $physicalPath (Everyone has $($ace.FileSystemRights))"
                    }
                }
            }
        }

        if ($vulnerableDirs.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "FTP directories with excessive permissions: $($vulnerableDirs -join '; ')"
        } else {
            $result.Details = "FTP directories do not grant 'Everyone' write/modify access."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking FTP directory permissions: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W22

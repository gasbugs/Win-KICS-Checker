# W-21: 암호화되지 않는 FTP 서비스 비활성화
function Test-W21 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-21"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $ftpsvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
        $port21 = Get-NetTCPConnection -LocalPort 21 -ErrorAction SilentlyContinue |
            Where-Object { $_.State -eq 'Listen' }

        if (($ftpsvc -and $ftpsvc.Status -eq 'Running') -or $port21) {
            $result.Result  = "Vulnerable"
            $result.Details = "Unencrypted FTP service is active. FTP service status: $(if($ftpsvc){"$($ftpsvc.Status)"}else{'Not installed'}), Port 21 listening: $(if($port21){'Yes'}else{'No'})."
        } else {
            $result.Details = "FTP service is not running and port 21 is not listening."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking FTP service: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W21

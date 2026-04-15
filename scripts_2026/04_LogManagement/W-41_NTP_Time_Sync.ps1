# W-41: NTP 및 시각 동기화 설정 (신규 항목)
function Test-W41 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-41"
        Category  = "로그 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $w32timeSvc = Get-Service -Name "W32Time" -ErrorAction SilentlyContinue

        if (-not $w32timeSvc -or $w32timeSvc.Status -ne 'Running') {
            $result.Result  = "Vulnerable"
            $result.Details = "Windows Time service is not running (Status: $(if($w32timeSvc){"$($w32timeSvc.Status)"}else{'Not installed'}))."
            $result | ConvertTo-Json -Depth 4
            return
        }

        # NTP 서버 구성 확인
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
        $ntpServer = (Get-ItemProperty -Path $regPath -Name "NtpServer" -ErrorAction SilentlyContinue).NtpServer
        $type = (Get-ItemProperty -Path $regPath -Name "Type" -ErrorAction SilentlyContinue).Type

        if ($type -eq "NoSync") {
            $result.Result  = "Vulnerable"
            $result.Details = "Time synchronization type is set to 'NoSync'. NTP is not configured."
        } elseif ([string]::IsNullOrWhiteSpace($ntpServer)) {
            $result.Result  = "Vulnerable"
            $result.Details = "NTP server is not configured."
        } else {
            $result.Details = "Windows Time service is running. NTP server: $ntpServer, Type: $type."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking NTP settings: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W41

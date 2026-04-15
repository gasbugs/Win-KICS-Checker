# W-56: SMB 세션 중단 관리 설정 (신규 항목)
function Test-W56 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-56"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        $propName = "AutoDisconnect"

        # AutoDisconnect: 세션 유휴 시간(분) 후 자동 연결 해제. 권장: 15분 이하
        $maxRecommended = 15

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($null -eq $value) {
            $result.Result  = "Vulnerable"
            $result.Details = "SMB AutoDisconnect is not configured. Default value may be too high."
        } elseif ($value -le $maxRecommended) {
            $result.Details = "SMB AutoDisconnect is set to $value minutes (Recommended: <= $maxRecommended min)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "SMB AutoDisconnect is set to $value minutes, exceeding recommended $maxRecommended minutes."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking SMB session management: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W56

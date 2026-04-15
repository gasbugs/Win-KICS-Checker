# W-36: 원격터미널 접속 타임아웃 설정
function Test-W36 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-36"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $maxRecommendedMs = 1800000  # 30분

    try {
        $termSvc = Get-Service -Name "TermService" -ErrorAction SilentlyContinue
        if (-not $termSvc -or $termSvc.Status -ne 'Running') {
            $result.Result  = "Not Applicable"
            $result.Details = "Terminal Service is not running."
            $result | ConvertTo-Json -Depth 4
            return
        }

        # 정책 경로 우선, 없으면 직접 경로
        $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
        $directPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"

        $maxIdleTime = (Get-ItemProperty -Path $policyPath -Name "MaxIdleTime" -ErrorAction SilentlyContinue).MaxIdleTime
        if ($null -eq $maxIdleTime) {
            $maxIdleTime = (Get-ItemProperty -Path $directPath -Name "MaxIdleTime" -ErrorAction SilentlyContinue).MaxIdleTime
        }

        if ($null -eq $maxIdleTime -or $maxIdleTime -eq 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Remote terminal idle timeout is not set or unlimited (Value: $maxIdleTime)."
        } elseif ($maxIdleTime -le $maxRecommendedMs) {
            $minutes = [math]::Round($maxIdleTime / 60000)
            $result.Details = "Remote terminal idle timeout is set to $minutes minutes (Recommended: <= 30 min)."
        } else {
            $minutes = [math]::Round($maxIdleTime / 60000)
            $result.Result  = "Vulnerable"
            $result.Details = "Remote terminal idle timeout is $minutes minutes, exceeding recommended 30 minutes."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking remote terminal timeout: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W36

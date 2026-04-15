# W-63: 도메인 컨트롤러-사용자의 시간 동기화 (신규 항목)
function Test-W63 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-63"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        # 도메인 가입 여부 확인
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $isDomainJoined = $computerSystem.PartOfDomain

        if (-not $isDomainJoined) {
            $result.Result  = "Not Applicable"
            $result.Details = "This computer is not domain-joined. Domain controller time sync check is not applicable."
            $result | ConvertTo-Json -Depth 4
            return
        }

        # Windows Time 서비스 확인
        $w32timeSvc = Get-Service -Name "W32Time" -ErrorAction SilentlyContinue
        if (-not $w32timeSvc -or $w32timeSvc.Status -ne 'Running') {
            $result.Result  = "Vulnerable"
            $result.Details = "Windows Time service is not running on domain-joined computer."
            $result | ConvertTo-Json -Depth 4
            return
        }

        # NTP 타입 확인 - 도메인 환경에서는 NT5DS(도메인 계층) 권장
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
        $type = (Get-ItemProperty -Path $regPath -Name "Type" -ErrorAction SilentlyContinue).Type

        if ($type -eq "NT5DS") {
            $result.Details = "Time synchronization with domain controller is configured (Type: NT5DS). Domain: $($computerSystem.Domain)."
        } elseif ($type -eq "NTP") {
            $result.Details = "Time source is set to NTP instead of domain hierarchy. This may be appropriate for DC servers. Domain: $($computerSystem.Domain)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Time synchronization type is '$type'. Domain-joined computers should use 'NT5DS'. Domain: $($computerSystem.Domain)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking domain time synchronization: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W63

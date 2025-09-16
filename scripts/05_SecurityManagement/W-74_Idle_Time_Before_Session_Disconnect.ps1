<#
.SYNOPSIS
    Checks KISA security item W-74: Microsoft network server: Disconnect clients when logon hours expire.

.DESCRIPTION
    This script verifies that the security policy to automatically disconnect clients when their logon hours
    expire is enabled by checking its corresponding registry value.

.OUTPUTS
    A JSON object with the check result (Good or Vulnerable) and details.
#>
function Test-W74_DisconnectOnLogonHourExpire {
    [CmdletBinding()]
    param()
    
    # --- 점검 기본 정보 ---
    $checkItem = "W-74"
    $category = "Security Management"
    $result = "Good" # 기본 상태를 '양호'로 설정
    $details = ""

    try {
        # --- 점검 대상 레지스트리 경로 및 값 ---
        # "Microsoft 네트워크 서버: 로그온 시간이 만료되면 클라이언트 연결 끊기" 정책의 레지스트리 위치
        # 값 1 = 사용(Enabled), 값 0 = 사용 안 함(Disabled)
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "EnableForcedLogoff"
        $recommendedValue = 1 # '사용'은 값이 1 (DWORD)

        # 레지스트리 값 가져오기 (값이 없으면 $null 반환)
        $currentValue = (Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue).($valueName)

        if ($currentValue -eq $recommendedValue) {
            # 현재 값이 권장 값(1)과 일치하는 경우
            $result = "Good"
            $details = "Policy 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'. (Current Value: $currentValue)"
        } else {
            # 현재 값이 권장 값과 다르거나 없는 경우
            $result = "Vulnerable"
            $currentValueStr = if ($null -eq $currentValue) { "Not Found" } else { $currentValue }
            $details = "Policy 'Microsoft network server: Disconnect clients when logon hours expire' is not set to 'Enabled'. (Current Value: $currentValueStr)"
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking the registry: $($_.Exception.Message)"
    }

    # --- 결과를 JSON 형식으로 출력 ---
    $output = @{
        CheckItem = $checkItem
        Category  = $category
        Result    = $result
        Details   = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $output | ConvertTo-Json -Depth 4
}

# 함수 실행
Test-W74_DisconnectOnLogonHourExpire
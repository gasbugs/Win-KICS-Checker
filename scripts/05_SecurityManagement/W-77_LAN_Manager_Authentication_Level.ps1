<#
.SYNOPSIS
    Checks KISA security item W-77: Network security: LAN Manager authentication level.

.DESCRIPTION
    This script verifies that the LAN Manager authentication level is set to 'Send NTLMv2 response only' 
    (Level 3) or higher, which is considered a secure configuration.

.OUTPUTS
    A JSON object with the check result (Good or Vulnerable) and details.
#>
function Test-W77_LmCompatibilityLevel {
    [CmdletBinding()]
    param()
    
    # --- 점검 기본 정보 ---
    $checkItem = "W-77"
    $category = "Security Management"
    $result = "Good" # 기본 상태를 '양호'로 설정
    $details = ""

    try {
        # --- 점검 대상 레지스트리 경로 및 값 ---
        # "네트워크 보안: LAN Manager 인증 수준" 정책의 레지스트리 위치
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $valueName = "LmCompatibilityLevel"
        
        # 권장 값: 수준 3 ("NTLMv2 응답만 보내기") 이상
        # 수준 4, 5도 더 강력한 보안 설정이므로 양호로 판단합니다.
        $minRecommendedValue = 3

        # 레지스트리 값 가져오기 (값이 없으면 $null 반환)
        $currentValue = (Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue).($valueName)

        if ($null -eq $currentValue) {
            # 레지스트리 값이 존재하지 않는 경우 (기본값은 보안에 취약)
            $result = "Vulnerable"
            $details = "Policy 'Network security: LAN Manager authentication level' is not configured. (Value is missing)"
        } elseif ($currentValue -lt $minRecommendedValue) {
            # 현재 값이 권장 수준(3)보다 낮은 경우
            $result = "Vulnerable"
            $details = "Policy 'Network security: LAN Manager authentication level' is set to a weak level. (Current Value: $currentValue, Recommended: 3 or higher)"
        } else {
            # 현재 값이 권장 수준(3) 이상인 경우
            $result = "Good"
            $details = "Policy 'Network security: LAN Manager authentication level' is set to a secure level. (Current Value: $currentValue)"
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
Test-W77_LmCompatibilityLevel
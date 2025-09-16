<#
.SYNOPSIS
    Checks KISA security item W-73: Devices: Prevent users from installing printer drivers.

.DESCRIPTION
    This script verifies that the security policy preventing non-administrators from installing printer drivers
    is enabled by checking its corresponding registry value.

.OUTPUTS
    A JSON object with the check result (Good or Vulnerable) and details.
#>
function Test-W73_PreventPrinterDriverInstallation {
    [CmdletBinding()]
    param()
    
    # --- 점검 기본 정보 ---
    $checkItem = "W-73"
    $category = "Security Management"
    $result = "Good" # 기본 상태를 '양호'로 설정
    $details = ""

    try {
        # --- 점검 대상 레지스트리 경로 및 값 ---
        # "장치: 사용자가 프린터 드라이버를 설치할 수 없게 함" 정책의 레지스트리 위치
        # 값 1 = 사용(Enabled), 값 0 = 사용 안 함(Disabled)
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
        $valueName = "AddPrinterDrivers"
        $recommendedValue = 1 # '사용'은 값이 1 (DWORD)

        # 레지스트리 값 가져오기 (값이 없거나 경로가 없으면 $null 반환)
        $currentValue = (Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue).($valueName)

        if ($currentValue -eq $recommendedValue) {
            # 현재 값이 권장 값(1)과 일치하는 경우
            $result = "Good"
            $details = "Policy 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'. (Current Value: $currentValue)"
        } else {
            # 현재 값이 권-장 값과 다르거나 없는 경우
            $result = "Vulnerable"
            $details = "Policy 'Devices: Prevent users from installing printer drivers' is not set to 'Enabled'. (Current Value: $($currentValue | Out-String | ForEach-Object { $_.Trim() }))"
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
Test-W73_PreventPrinterDriverInstallation
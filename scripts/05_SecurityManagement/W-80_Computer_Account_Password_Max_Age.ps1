<#
.SYNOPSIS
    Checks KISA security item W-80: Domain member machine account password management.

.DESCRIPTION
    This script verifies two security policies related to machine account passwords:
    1. 'Disable machine account password changes' should be Disabled.
    2. 'Maximum machine account password age' should be set to 90 days.

.OUTPUTS
    A JSON object with the check result (Good or Vulnerable) and details.
#>
function Test-W80_MachineAccountPasswordPolicy {
    [CmdletBinding()]
    param()
    
    # --- 점검 기본 정보 ---
    $checkItem = "W-80"
    $category = "Security Management"
    $result = "Good" # 기본 상태를 '양호'로 설정
    $vulnerableFindings = [System.Collections.Generic.List[string]]::new()

    try {
        # --- 점검 대상 레지스트리 경로 ---
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
        
        # --- 1. "컴퓨터 계정 암호 변경 사항 사용 안 함" 정책 점검 ---
        $disableChangeValueName = "DisablePasswordChange"
        $recommendedDisableChangeValue = 0 # '사용 안 함'은 값이 0 (DWORD)
        
        $currentDisableChangeValue = (Get-ItemProperty -Path $registryPath -Name $disableChangeValueName -ErrorAction SilentlyContinue).($disableChangeValueName)

        if ($currentDisableChangeValue -ne $recommendedDisableChangeValue) {
            $result = "Vulnerable"
            $currentValStr = if ($null -eq $currentDisableChangeValue) { "Not Found" } else { $currentDisableChangeValue }
            $vulnerableFindings.Add("Policy 'Disable machine account password changes' is not 'Disabled'. (Current: $currentValStr)")
        }

        # --- 2. "컴퓨터 계정 암호의 최대 사용 기간" 정책 점검 ---
        $maxAgeValueName = "MaximumPasswordAge"
        $recommendedMaxAgeValue = 90 # '90일'
        
        $currentMaxAgeValue = (Get-ItemProperty -Path $registryPath -Name $maxAgeValueName -ErrorAction SilentlyContinue).($maxAgeValueName)

        if ($currentMaxAgeValue -ne $recommendedMaxAgeValue) {
            $result = "Vulnerable"
            $currentValStr = if ($null -eq $currentMaxAgeValue) { "Not Found or Not Set to 90" } else { $currentMaxAgeValue }
            $vulnerableFindings.Add("Policy 'Maximum machine account password age' is not set to '90' days. (Current: $currentValStr)")
        }

        # --- 최종 결과 정리 ---
        if ($result -eq "Vulnerable") {
            $details = "Machine account password policies are not compliant.`n" + ($vulnerableFindings -join "`n")
        } else {
            $details = "Machine account password policies are configured correctly."
            $details += "`n- 'Disable password changes' is Disabled (Value: $currentDisableChangeValue)"
            $details += "`n- 'Maximum password age' is 90 days (Value: $currentMaxAgeValue)"
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
Test-W80_MachineAccountPasswordPolicy
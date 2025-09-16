<#
.SYNOPSIS
    Checks KISA security item W-75: Interactive logon message and title for users.

.DESCRIPTION
    This script verifies that both the logon message title (LegalNoticeCaption) and text (LegalNoticeText)
    are configured and not empty, by checking their corresponding registry values.

.OUTPUTS
    A JSON object with the check result (Good or Vulnerable) and details.
#>
function Test-W75_LogonBannerMessage {
    [CmdletBinding()]
    param()
    
    # --- 점검 기본 정보 ---
    $checkItem = "W-75"
    $category = "Security Management"
    $result = "Good" # 기본 상태를 '양호'로 설정
    $vulnerableFindings = [System.Collections.Generic.List[string]]::new()

    try {
        # --- 점검 대상 레지스트리 경로 및 값 ---
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        
        # 레지스트리 값 가져오기
        $caption = (Get-ItemProperty -Path $registryPath -Name "LegalNoticeCaption" -ErrorAction SilentlyContinue)."LegalNoticeCaption"
        $text = (Get-ItemProperty -Path $registryPath -Name "LegalNoticeText" -ErrorAction SilentlyContinue)."LegalNoticeText"

        # 1. 메시지 제목 (LegalNoticeCaption) 점검
        if ([string]::IsNullOrWhiteSpace($caption)) {
            $result = "Vulnerable"
            $vulnerableFindings.Add("Logon message title (LegalNoticeCaption) is not set.")
        }

        # 2. 메시지 내용 (LegalNoticeText) 점검
        if ([string]::IsNullOrWhiteSpace($text)) {
            $result = "Vulnerable"
            $vulnerableFindings.Add("Logon message text (LegalNoticeText) is not set.")
        }

        # --- 최종 결과 정리 ---
        if ($result -eq "Vulnerable") {
            $details = "The interactive logon banner is not properly configured.`n" + ($vulnerableFindings -join "`n")
        } else {
            $details = "The interactive logon banner title and text are both configured correctly."
            $details += "`n- Title: $caption`n- Text: $text"
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
Test-W75_LogonBannerMessage
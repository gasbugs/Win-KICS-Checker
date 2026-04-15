# W-57: 로그온 시 경고 메시지 설정
function Test-W57 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-57"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

        $caption = (Get-ItemProperty -Path $regPath -Name "LegalNoticeCaption" -ErrorAction SilentlyContinue).LegalNoticeCaption
        $text    = (Get-ItemProperty -Path $regPath -Name "LegalNoticeText" -ErrorAction SilentlyContinue).LegalNoticeText

        $issues = @()
        if ([string]::IsNullOrWhiteSpace($caption)) { $issues += "LegalNoticeCaption is not configured" }
        if ([string]::IsNullOrWhiteSpace($text))    { $issues += "LegalNoticeText is not configured" }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Logon warning message issues: $($issues -join '; ')"
        } else {
            $result.Details = "Logon warning message is configured. Title: '$caption'."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking warning message: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W57

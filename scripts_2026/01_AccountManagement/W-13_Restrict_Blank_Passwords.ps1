# W-13: 콘솔 로그온 시 로컬 계정에서 빈 암호 사용 제한
function Test-W13 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-13"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $propName = "LimitBlankPasswordUse"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($value -eq 1) {
            $result.Details = "Blank password use is limited to console logon only (LimitBlankPasswordUse: 1)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Blank password restriction is not enabled (LimitBlankPasswordUse: $value)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W13

# W-50: 보안 감사를 로그할 수 없는 경우 즉시 시스템 종료
function Test-W50 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-50"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $propName = "CrashOnAuditFail"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($null -eq $value -or $value -eq 0) {
            $result.Details = "CrashOnAuditFail is disabled (Value: $($value ?? 'Not Set')). System will not shut down on audit failure."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "CrashOnAuditFail is enabled (Value: $value). System may shut down unexpectedly."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking CrashOnAuditFail: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W50

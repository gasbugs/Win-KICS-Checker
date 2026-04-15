# W-51: SAM 계정과 공유의 익명 열거 허용 안 함
function Test-W51 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-51"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $restrictAnon    = (Get-ItemProperty -Path $regPath -Name "RestrictAnonymous" -ErrorAction SilentlyContinue).RestrictAnonymous
        $restrictAnonSAM = (Get-ItemProperty -Path $regPath -Name "RestrictAnonymousSAM" -ErrorAction SilentlyContinue).RestrictAnonymousSAM

        $issues = @()
        if ($restrictAnon -ne 1)    { $issues += "RestrictAnonymous=$restrictAnon (Required: 1)" }
        if ($restrictAnonSAM -ne 1) { $issues += "RestrictAnonymousSAM=$restrictAnonSAM (Required: 1)" }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Anonymous SAM enumeration not fully restricted: $($issues -join '; ')"
        } else {
            $result.Details = "Anonymous SAM enumeration is properly restricted."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking anonymous SAM enumeration: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W51

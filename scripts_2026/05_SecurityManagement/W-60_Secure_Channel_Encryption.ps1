# W-60: 보안 채널 데이터 디지털 암호화 또는 서명
function Test-W60 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-60"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $policies = @("RequireSignOrSeal", "SealSecureChannel", "SignSecureChannel")
        $issues = @()

        foreach ($policy in $policies) {
            $line = $content | Select-String -Pattern "$policy"
            if ($line) {
                $value = $line.ToString().Split('=')[1].Split(',')[-1].Trim()
                if ($value -ne "1") {
                    $issues += "$policy=$value (Required: 1)"
                }
            } else {
                $issues += "$policy not found in policy"
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Secure channel issues: $($issues -join '; ')"
        } else {
            $result.Details = "Secure channel data encryption and signing are properly configured."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking secure channel settings: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W60

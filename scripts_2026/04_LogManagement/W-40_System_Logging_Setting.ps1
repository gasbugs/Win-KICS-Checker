# W-40: 정책에 따른 시스템 로깅 설정
function Test-W40 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem       = "W-40"
        Category        = "로그 관리"
        Result          = "Good"
        Details         = ""
        NonCompliant    = @()
        Timestamp       = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        # 기본 감사 정책 권장값
        $recommendedPolicies = @{
            "Logon/Logoff"        = "Success and Failure"
            "Account Logon"       = "Success and Failure"
            "Account Management"  = "Success and Failure"
            "Object Access"       = "Failure"
            "Policy Change"       = "Success"
            "Privilege Use"       = "Failure"
            "System"              = "Success and Failure"
        }

        $auditOutput = auditpol.exe /get /category:* 2>&1
        $nonCompliant = @()

        foreach ($policy in $recommendedPolicies.GetEnumerator()) {
            $line = $auditOutput | Select-String -Pattern $policy.Key -SimpleMatch
            if ($line) {
                $currentSetting = $line.ToString().Trim() -replace ".*\s{2,}", ""
                if ($currentSetting -ne $policy.Value) {
                    $nonCompliant += "$($policy.Key): Current='$currentSetting', Recommended='$($policy.Value)'"
                }
            }
        }

        $result.NonCompliant = $nonCompliant

        if ($nonCompliant.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Audit policies not meeting recommendations: $($nonCompliant -join '; ')"
        } else {
            $result.Details = "All audit policies meet recommended settings."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking audit policies: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W40

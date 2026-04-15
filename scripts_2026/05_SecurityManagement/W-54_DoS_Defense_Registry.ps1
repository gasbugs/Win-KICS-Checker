# W-54: DoS 공격 방어 레지스트리 설정
function Test-W54 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-54"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

        $checks = @(
            @{ Name = "SynAttackProtect";     Required = @(1, 2); Desc = "must be 1 or 2" }
            @{ Name = "EnableDeadGWDetect";   Required = @(0);    Desc = "must be 0" }
            @{ Name = "KeepAliveTime";        Required = @(300000); Desc = "must be 300000" }
            @{ Name = "NoNameReleaseOnDemand"; Required = @(1);    Desc = "must be 1" }
        )

        $issues = @()
        foreach ($check in $checks) {
            $value = (Get-ItemProperty -Path $regPath -Name $check.Name -ErrorAction SilentlyContinue).($check.Name)
            if ($null -eq $value -or $value -notin $check.Required) {
                $issues += "$($check.Name)=$($value ?? 'Not Set') ($($check.Desc))"
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "DoS defense registry issues: $($issues -join '; ')"
        } else {
            $result.Details = "All DoS defense registry settings are properly configured."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking DoS defense settings: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W54

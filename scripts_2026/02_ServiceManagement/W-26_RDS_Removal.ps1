# W-26: RDS(Remote Data Services) 제거
function Test-W26 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-26"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $osVersion = [System.Environment]::OSVersion.Version

        # Windows Server 2008+ (6.0+)에서는 RDS가 기본 제거됨
        if ($osVersion.Major -ge 6) {
            $result.Result  = "Not Applicable"
            $result.Details = "OS version $($osVersion.Major).$($osVersion.Minor) does not include RDS by default."
            $result | ConvertTo-Json -Depth 4
            return
        }

        # 레거시 OS: MSADC 가상 디렉터리 및 레지스트리 확인
        $rdsRegPaths = @(
            "HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\ADCLaunch",
            "HKLM:\SOFTWARE\Microsoft\DataFactory"
        )
        $issues = @()

        foreach ($path in $rdsRegPaths) {
            if (Test-Path $path) {
                $issues += "Registry key found: $path"
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "RDS components detected: $($issues -join '; ')"
        } else {
            $result.Details = "No RDS components detected."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking RDS: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W26

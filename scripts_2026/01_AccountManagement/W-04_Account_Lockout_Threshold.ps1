# W-04: 계정 잠금 임계값 설정
function Test-W04 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-04"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $lockoutThreshold = ($content | Select-String -Pattern "LockoutBadCount" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($null -eq $lockoutThreshold -or $lockoutThreshold -eq 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "The account lockout threshold is not set (Current value: $lockoutThreshold)."
        } elseif ($lockoutThreshold -ge 1 -and $lockoutThreshold -le 5) {
            $result.Details = "The account lockout threshold is set to $lockoutThreshold (Recommended: 1-5)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "The account lockout threshold is set to $lockoutThreshold, which is outside the recommended range (1-5)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the account lockout threshold: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W04

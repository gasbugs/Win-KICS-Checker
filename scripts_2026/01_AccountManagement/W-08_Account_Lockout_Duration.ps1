# W-08: 계정 잠금 기간 설정
function Test-W08 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-08"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $minRecommendedMinutes = 60

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $lockoutDuration = ($content | Select-String -Pattern "LockoutDuration" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $resetLockoutCount = ($content | Select-String -Pattern "ResetLockoutCount" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        $isDurationGood = $lockoutDuration -ge $minRecommendedMinutes
        $isResetGood    = $resetLockoutCount -ge $minRecommendedMinutes

        if ($isDurationGood -and $isResetGood) {
            $result.Details = "Account lockout duration ($lockoutDuration min) and reset counter ($resetLockoutCount min) meet recommended values (>= 60 min)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Account lockout duration ($lockoutDuration min) or reset counter ($resetLockoutCount min) below recommended 60 minutes."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking account lockout policies: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W08

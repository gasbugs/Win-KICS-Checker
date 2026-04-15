# W-47: 화면보호기 설정
function Test-W47 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-47"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath = "HKCU:\Control Panel\Desktop"
        $maxTimeout = 600  # 10분

        $active  = (Get-ItemProperty -Path $regPath -Name "ScreenSaveActive" -ErrorAction SilentlyContinue).ScreenSaveActive
        $timeout = (Get-ItemProperty -Path $regPath -Name "ScreenSaveTimeOut" -ErrorAction SilentlyContinue).ScreenSaveTimeOut
        $secure  = (Get-ItemProperty -Path $regPath -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue).ScreenSaverIsSecure

        $issues = @()

        if ($active -ne "1") {
            $issues += "ScreenSaveActive=$active (Required: 1)"
        }
        if ($null -eq $timeout -or [int]$timeout -gt $maxTimeout) {
            $issues += "ScreenSaveTimeOut=$timeout (Required: <= $maxTimeout sec)"
        }
        if ($secure -ne "1") {
            $issues += "ScreenSaverIsSecure=$secure (Required: 1)"
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Screensaver issues: $($issues -join '; ')"
        } else {
            $result.Details = "Screensaver is enabled, password-protected, and timeout is ${timeout}s (<= ${maxTimeout}s)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking screensaver settings: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W47

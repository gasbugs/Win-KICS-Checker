# W-42: 이벤트 로그 관리 설정
function Test-W42 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-42"
        Category  = "로그 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $minSizeKB = 10240  # 10MB

    try {
        $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue |
            Where-Object { $_.IsEnabled }
        $issues = @()

        foreach ($log in $logs) {
            $sizeKB = [math]::Round($log.MaximumSizeInBytes / 1024)
            if ($sizeKB -lt $minSizeKB) {
                $issues += "$($log.LogName): Size=${sizeKB}KB (Required: >=${minSizeKB}KB)"
            }
            if ($log.LogMode -ne 'Circular') {
                $issues += "$($log.LogName): Mode=$($log.LogMode) (Required: Circular)"
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Event log issues: $($issues -join '; ')"
        } else {
            $result.Details = "All event logs meet size (>= ${minSizeKB}KB) and retention (Circular) requirements."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking event log settings: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W42

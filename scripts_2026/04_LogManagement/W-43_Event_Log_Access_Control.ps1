# W-43: 이벤트 로그 파일 접근 통제 설정 (신규 항목)
function Test-W43 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-43"
        Category  = "로그 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $logDir = "$env:SystemRoot\System32\winevt\Logs"

        if (-not (Test-Path $logDir)) {
            $result.Result  = "Error"
            $result.Details = "Event log directory not found: $logDir"
            $result | ConvertTo-Json -Depth 4
            return
        }

        $logFiles = Get-ChildItem -Path $logDir -Filter "*.evtx" -ErrorAction SilentlyContinue |
            Select-Object -First 10  # 주요 로그 파일만 점검

        $issues = @()

        foreach ($file in $logFiles) {
            $acl = Get-Acl $file.FullName -ErrorAction SilentlyContinue
            foreach ($ace in $acl.Access) {
                $identity = $ace.IdentityReference.Value
                # Everyone 또는 Users 그룹에 Write 이상 권한이 있는지 확인
                if ($identity -eq 'Everyone' -and $ace.FileSystemRights -match 'Write|Modify|FullControl') {
                    $issues += "$($file.Name): Everyone has $($ace.FileSystemRights)"
                }
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Event log files with excessive permissions: $($issues -join '; ')"
        } else {
            $result.Details = "Event log files have proper access control settings."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking event log file permissions: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W43

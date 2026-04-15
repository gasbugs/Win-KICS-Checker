# W-39: 백신 프로그램 업데이트
function Test-W39 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-39"
        Category  = "패치 관리"
        Result    = "Manual Check Required"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $winDefend = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue

        if ($winDefend -and $winDefend.Status -eq 'Running') {
            $result.Details = "Windows Defender service is running. Verify that virus definitions are up to date."
        } elseif ($winDefend) {
            $result.Details = "Windows Defender service is installed but not running (Status: $($winDefend.Status)). Verify antivirus update status."
        } else {
            $result.Details = "Windows Defender service not found. Verify third-party antivirus update status."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking antivirus update status: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W39

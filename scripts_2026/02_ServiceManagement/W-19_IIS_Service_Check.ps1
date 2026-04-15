# W-19: 불필요한 IIS 서비스 구동 점검
function Test-W19 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-19"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $w3svc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue

        if ($w3svc -and $w3svc.Status -eq 'Running') {
            $result.Result  = "Vulnerable"
            $result.Details = "IIS Web Service (W3SVC) is running. Disable if not required."
        } elseif ($w3svc) {
            $result.Details = "IIS Web Service (W3SVC) is installed but not running (Status: $($w3svc.Status))."
        } else {
            $result.Details = "IIS Web Service (W3SVC) is not installed."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking IIS service: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W19

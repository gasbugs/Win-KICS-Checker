# W-34: Telnet 서비스 비활성화
function Test-W34 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-34"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $telnetSvc = Get-Service -Name "TlntSvr" -ErrorAction SilentlyContinue

        if ($telnetSvc -and $telnetSvc.Status -eq 'Running') {
            $result.Result  = "Vulnerable"
            $result.Details = "Telnet service is running. Disable immediately."
        } elseif ($telnetSvc) {
            $result.Details = "Telnet service is installed but not running (Status: $($telnetSvc.Status))."
        } else {
            $result.Details = "Telnet service is not installed."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking Telnet service: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W34

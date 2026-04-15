# W-44: 원격으로 액세스할 수 있는 레지스트리 경로
function Test-W44 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-44"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $remoteRegSvc = Get-Service -Name "RemoteRegistry" -ErrorAction SilentlyContinue

        if ($remoteRegSvc -and $remoteRegSvc.Status -eq 'Running') {
            $result.Result  = "Vulnerable"
            $result.Details = "Remote Registry service is running. Disable to prevent remote registry access."
        } elseif ($remoteRegSvc) {
            $result.Details = "Remote Registry service is installed but not running (Status: $($remoteRegSvc.Status))."
        } else {
            $result.Details = "Remote Registry service is not installed."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking Remote Registry service: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W44

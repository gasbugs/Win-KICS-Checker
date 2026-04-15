# W-48: 로그온하지 않고 시스템 종료 허용
function Test-W48 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-48"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $propName = "ShutdownWithoutLogon"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($value -eq 0) {
            $result.Details = "Shutdown without logon is disabled (ShutdownWithoutLogon: 0)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Shutdown without logon is enabled (ShutdownWithoutLogon: $value)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking shutdown policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W48

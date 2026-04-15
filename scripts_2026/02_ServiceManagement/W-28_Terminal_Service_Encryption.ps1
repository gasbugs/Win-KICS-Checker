# W-28: 터미널 서비스 암호화 수준 설정
function Test-W28 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-28"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $propName = "MinEncryptionLevel"
        $minRecommended = 2

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($null -eq $value) {
            $result.Result  = "Vulnerable"
            $result.Details = "MinEncryptionLevel is not configured."
        } elseif ($value -ge $minRecommended) {
            $result.Details = "Terminal service encryption level is $value (Recommended: >= $minRecommended)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Terminal service encryption level is $value, below recommended $minRecommended."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking terminal service encryption: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W28

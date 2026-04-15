# W-45: 백신 프로그램 설치
function Test-W45 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-45"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $avProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class "AntivirusProduct" -ErrorAction SilentlyContinue

        if ($avProducts) {
            $avNames = ($avProducts | ForEach-Object { $_.displayName }) -join ', '
            $result.Details = "Antivirus product(s) detected: $avNames."
        } else {
            # SecurityCenter2 없는 Server 환경에서 WinDefend 체크
            $winDefend = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
            if ($winDefend -and $winDefend.Status -eq 'Running') {
                $result.Details = "Windows Defender service is running."
            } else {
                $result.Result  = "Vulnerable"
                $result.Details = "No active antivirus product detected."
            }
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking antivirus installation: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W45

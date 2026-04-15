# W-17: 하드디스크 기본 공유 제거
function Test-W17 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-17"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        $autoShareServer = (Get-ItemProperty -Path $regPath -Name "AutoShareServer" -ErrorAction SilentlyContinue).AutoShareServer
        $autoShareWks    = (Get-ItemProperty -Path $regPath -Name "AutoShareWks" -ErrorAction SilentlyContinue).AutoShareWks

        $defaultShares = Get-WmiObject -Class Win32_Share -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^[A-Z]\$$' }

        $issues = @()

        if ($autoShareServer -ne 0 -and $autoShareWks -ne 0) {
            $issues += "AutoShare registry not disabled (Server: $autoShareServer, Wks: $autoShareWks)"
        }
        if ($defaultShares) {
            $shareNames = ($defaultShares | ForEach-Object { $_.Name }) -join ', '
            $issues += "Default shares exist: $shareNames"
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = $issues -join "; "
        } else {
            $result.Details = "Default administrative shares are disabled and no default shares exist."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking default shares: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W17

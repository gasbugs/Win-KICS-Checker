# W-55: 사용자가 프린터 드라이버를 설치할 수 없게 함
function Test-W55 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-55"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
        $propName = "AddPrinterDrivers"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($value -eq 1) {
            $result.Details = "Users are prevented from installing printer drivers (AddPrinterDrivers: 1)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Users may install printer drivers (AddPrinterDrivers: $(if ($null -ne $value) { $value } else { 'Not Set' }))."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking printer driver policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W55

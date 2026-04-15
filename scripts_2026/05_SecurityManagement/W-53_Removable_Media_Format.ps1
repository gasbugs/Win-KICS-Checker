# W-53: 이동식 미디어 포맷 및 꺼내기 허용
function Test-W53 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-53"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $propName = "allocateDASD"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        # 0=Administrators only (Good), 1=Administrators and Power Users, 2=Administrators and Interactive Users
        if ($value -eq "0") {
            $result.Details = "Removable media format/eject is restricted to Administrators only (allocateDASD: 0)."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Removable media format/eject is not restricted to Administrators (allocateDASD: $($value ?? 'Not Set'))."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking removable media policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W53

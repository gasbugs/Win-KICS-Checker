# W-52: Autologon 기능 제어
function Test-W52 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-52"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $propName = "AutoAdminLogon"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($null -eq $value -or $value -eq "0") {
            $result.Details = "Autologon is disabled (AutoAdminLogon: $(if ($null -ne $value) { $value } else { 'Not Set' }))."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Autologon is enabled (AutoAdminLogon: $value). Disable for security."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking Autologon: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W52

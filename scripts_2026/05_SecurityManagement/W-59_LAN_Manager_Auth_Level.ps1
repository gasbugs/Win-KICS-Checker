# W-59: LAN Manager 인증 수준
function Test-W59 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-59"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $propName = "LmCompatibilityLevel"
        $minLevel = 3  # NTLMv2 response only

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($null -eq $value -or $value -lt $minLevel) {
            $result.Result  = "Vulnerable"
            $result.Details = "LAN Manager authentication level is $(if ($null -ne $value) { $value } else { 'Not Set' }) (Required: >= $minLevel for NTLMv2)."
        } else {
            $result.Details = "LAN Manager authentication level is $value (NTLMv2 or higher)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking LAN Manager authentication: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W59

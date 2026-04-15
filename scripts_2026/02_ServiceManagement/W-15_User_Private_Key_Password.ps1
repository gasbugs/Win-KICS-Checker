# W-15: 사용자 개인키 사용 시 암호 입력 (신규 항목)
function Test-W15 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-15"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        # 레지스트리에서 개인키 보호 수준 확인
        # ForceKeyProtection: 0=사용자 선택, 1=경고 표시, 2=항상 암호 요구
        $regPath  = "HKLM:\SOFTWARE\Policies\Microsoft\Cryptography"
        $propName = "ForceKeyProtection"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($null -eq $value) {
            $result.Result  = "Vulnerable"
            $result.Details = "ForceKeyProtection is not configured. Users may store private keys without password protection."
        } elseif ($value -ge 2) {
            $result.Details = "ForceKeyProtection is set to $value. Users must enter a password when using private keys."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "ForceKeyProtection is set to $value (Required: >= 2 for mandatory password)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking ForceKeyProtection policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W15

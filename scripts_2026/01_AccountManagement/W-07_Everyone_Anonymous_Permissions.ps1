# W-07: Everyone 사용 권한을 익명 사용자에게 적용
function Test-W07 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-07"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $propName = "EveryoneIncludesAnonymous"

        if (Test-Path $regPath) {
            $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

            if ($null -eq $value -or $value -eq 0) {
                $result.Details = "Everyone permissions do not include anonymous users (EveryoneIncludesAnonymous: $(if ($null -ne $value) { $value } else { 'Not Set' }))."
            } else {
                $result.Result  = "Vulnerable"
                $result.Details = "Everyone permissions include anonymous users (EveryoneIncludesAnonymous: $value)."
            }
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "Registry path '$regPath' not found."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W07

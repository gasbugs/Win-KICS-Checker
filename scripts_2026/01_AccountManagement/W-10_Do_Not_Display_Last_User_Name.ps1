# W-10: 마지막 사용자 이름 표시 안 함
function Test-W10 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-10"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $propName = "DontDisplayLastUserName"

        $value = (Get-ItemProperty -Path $regPath -Name $propName -ErrorAction SilentlyContinue).$propName

        if ($value -eq 1) {
            $result.Details = "The 'Do not display last user name' policy is enabled."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "The 'Do not display last user name' policy is disabled (Current value: $value)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W10

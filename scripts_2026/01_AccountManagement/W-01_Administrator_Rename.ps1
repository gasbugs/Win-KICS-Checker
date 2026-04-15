# W-01: Administrator 계정 이름 변경 등 보안성 강화
function Test-W01 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-01"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $adminUser = Get-LocalUser | Where-Object { $_.SID.Value.EndsWith('-500') }

        if ($adminUser) {
            $adminName = $adminUser.Name
            if ($adminName -eq "Administrator") {
                $result.Result  = "Vulnerable"
                $result.Details = "The default administrator account name has not been changed."
            } else {
                $result.Details = "The default administrator account name has been changed to '$adminName'."
            }
        } else {
            $result.Result  = "Error"
            $result.Details = "Could not find the built-in administrator account (SID ending in -500)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the Administrator account: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W01

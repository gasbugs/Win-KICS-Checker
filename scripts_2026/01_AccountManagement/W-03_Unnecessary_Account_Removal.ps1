# W-03: 불필요한 계정 제거
function Test-W03 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem    = "W-03"
        Category     = "계정 관리"
        Result       = "Manual Check Required"
        Details      = "Review the list of user accounts to identify any unnecessary accounts."
        UserAccounts = @()
        Timestamp    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $users = Get-LocalUser
        $result.UserAccounts = foreach ($user in $users) {
            @{
                Name            = $user.Name
                Enabled         = $user.Enabled
                PasswordLastSet = "$($user.PasswordLastSet)"
                Description     = $user.Description
                SID             = $user.SID.Value
            }
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while retrieving the user list: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W03

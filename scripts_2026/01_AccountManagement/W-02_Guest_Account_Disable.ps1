# W-02: Guest 계정 비활성화
function Test-W02 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-02"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $guestUser = Get-LocalUser -Name "Guest"

        if ($guestUser.Enabled) {
            $result.Result  = "Vulnerable"
            $result.Details = "The Guest account is enabled."
        } else {
            $result.Details = "The Guest account is disabled."
        }
    }
    catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
        $result.Details = "The Guest account does not exist."
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the Guest account status: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W02

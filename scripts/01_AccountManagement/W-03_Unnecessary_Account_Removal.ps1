# W-03: Unnecessary Accounts Check

$result = [PSCustomObject]@{
    "CheckItem" = "W-03"
    "Category" = "Account Management"
    "Result" = "Manual Check Required"
    "Details" = "Review the list of user accounts in the 'UserAccounts' property to identify any unnecessary accounts."
    "UserAccounts" = @()
    "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

try {
    # Get all local user accounts
    $users = Get-LocalUser

    $userList = foreach ($user in $users) {
        [PSCustomObject]@{
            Name = $user.Name
            Enabled = $user.Enabled
            PasswordLastSet = $user.PasswordLastSet
            Description = $user.Description
            SID = $user.SID.Value
        }
    }

    $result.UserAccounts = $userList
} catch {
    $result.Result = "Error"
    $result.Details = "An error occurred while retrieving the user list. $_"
}

# Output the result as a more readable, expanded JSON
$result | ConvertTo-Json

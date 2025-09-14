# W-02: Guest Account Deactivation Check

$result = [PSCustomObject]@{
    "CheckItem" = "W-02"
    "Category" = "Account Management"
    "Result" = ""
    "Details" = ""
    "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

try {
    # Get the local Guest user account
    $guestUser = Get-LocalUser -Name "Guest"

    if ($guestUser.Enabled) {
        $result.Result = "Vulnerable"
        $result.Details = "The Guest account is enabled."
    } else {
        $result.Result = "Good"
        $result.Details = "The Guest account is disabled."
    }
} catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
    # If the Guest account doesn't exist, it's considered secure for this check.
    $result.Result = "Good"
    $result.Details = "The Guest account does not exist."
} catch {
    $result.Result = "Error"
    $result.Details = "An error occurred while checking the Guest account status. $_"
}

$result | ConvertTo-Json -Compress

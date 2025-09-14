# W-01: Administrator Account Name Check

$result = [PSCustomObject]@{
    "CheckItem" = "W-01"
    "Category" = "Account Management"
    "Result" = ""
    "Details" = ""
    "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

try {
    # Get the local user with the well-known SID for the administrator account (ends with -500)
    $adminUser = Get-LocalUser | Where-Object { $_.SID.Value.EndsWith('-500') }

    if ($adminUser) {
        $adminName = $adminUser.Name
        if ($adminName -eq "Administrator") {
            $result.Result = "Vulnerable"
            $result.Details = "The default administrator account name has not been changed."
        } else {
            $result.Result = "Good"
            $result.Details = "The default administrator account name has been changed to '$adminName'."
        }
    } else {
        $result.Result = "Error"
        $result.Details = "Could not find the built-in administrator account (SID ending in -500)."
    }
} catch {
    $result.Result = "Error"
    $result.Details = "An error occurred while checking the Administrator account information. $_"
}

$result | ConvertTo-Json -Compress

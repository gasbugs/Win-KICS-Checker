# W-04: Account Lockout Threshold Check

$result = [PSCustomObject]@{
    "CheckItem" = "W-04"
    "Category" = "Account Management"
    "Result" = ""
    "Details" = ""
    "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

try {
    $netAccountsOutput = net accounts
    # The lockout threshold is on the 6th line (index 5) of the output.
    $lockoutThresholdLine = $netAccountsOutput[5]
    
    # The value is the part after the colon.
    $thresholdValueString = $lockoutThresholdLine.Split(':')[-1].Trim()

    # Check if the value is a number.
    if ($thresholdValueString -match '^\d+$') {
        $threshold = [int]$thresholdValueString
        if ($threshold -gt 0 -and $threshold -le 5) {
            $result.Result = "Good"
            $result.Details = "The account lockout threshold is set to $threshold, which is within the recommended range (1-5)."
        } else {
            $result.Result = "Vulnerable"
            $result.Details = "The account lockout threshold is set to $threshold, which is outside the recommended range (1-5)."
        }
    } else {
        # If it's not a number, it's likely "Never" or "없음", which is vulnerable.
        $result.Result = "Vulnerable"
        $result.Details = "The account lockout threshold is not set to a specific number (Current value: $thresholdValueString)."
    }
} catch {
    $result.Result = "Error"
    $result.Details = "An error occurred while checking the account lockout threshold. $_"
}

$result | ConvertTo-Json -Compress

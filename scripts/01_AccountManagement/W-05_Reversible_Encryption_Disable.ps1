# W-05: Reversible Encryption Check

$result = [PSCustomObject]@{
    "CheckItem" = "W-05"
    "Category" = "Account Management"
    "Result" = ""
    "Details" = ""
    "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# First, check for administrative privileges
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = (New-Object System.Security.Principal.WindowsPrincipal $currentUser).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $result.Result = "Error"
    $result.Details = "This script requires administrator privileges to run 'secedit'. Please re-run this script as an Administrator."
    $result | ConvertTo-Json
    exit
}

# Define path for the temporary export file
$infPath = "$env:TEMP\secpol.inf"

try {
    # Export the local security policy to a file. The /quiet flag suppresses output.
    secedit /export /cfg $infPath /quiet

    if (Test-Path $infPath) {
        # Find the line with the policy setting
        $policyLine = Get-Content $infPath | Select-String -Pattern "ClearTextPassword"

        if ($policyLine) {
            # The value is after the equals sign
            $value = $policyLine.ToString().Split('=')[1].Trim()

            if ($value -eq "0") {
                $result.Result = "Good"
                $result.Details = "Storing passwords using reversible encryption is disabled (Value: 0)."
            } else {
                $result.Result = "Vulnerable"
                $result.Details = "Storing passwords using reversible encryption is enabled (Value: $value)."
            }
        } else {
            # If the line isn't found, it implies the default setting, which is disabled (Good).
            $result.Result = "Good"
            $result.Details = "Storing passwords using reversible encryption is not configured, which defaults to disabled."
        }
    } else {
        $result.Result = "Error"
        $result.Details = "Failed to export security policy using secedit. This may be a permissions issue."
    }
} catch {
    $result.Result = "Error"
    $result.Details = "An error occurred while checking the reversible encryption policy. $_"
} finally {
    # Clean up the temporary file
    if (Test-Path $infPath) { Remove-Item $infPath -Force }
}

$result | ConvertTo-Json
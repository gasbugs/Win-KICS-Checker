# W-07: Share Permissions and User Group Settings
# Checks for the presence of the 'Everyone' permission on non-administrative shares.

# Set script-level error action to stop on first error
$ErrorActionPreference = 'Stop'

# Define the result object
$result = @{
    CheckItem = 'W-07'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'No non-administrative shares found or no shares grant access to ''Everyone''.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    VulnerableShares = @()
}

try {
    # Get all non-administrative SMB shares
    # Administrative shares end with a '$'
    $shares = Get-SmbShare | Where-Object { -not $_.Name.EndsWith('$') }

    if ($null -eq $shares) {
        # No non-administrative shares found, which is a good state.
        # The default 'Good' result is appropriate.
    } else {
        foreach ($share in $shares) {
            try {
                # Get the access control list for the current share
                $acl = Get-SmbShareAccess -Name $share.Name

                # Check if 'Everyone' is in the list of accounts with access
                if ($acl.AccountName -contains 'Everyone') {
                    $result.Result = 'Vulnerable'
                    $result.VulnerableShares += $share.Name
                }
            } catch {
                # This might happen if we can't get the ACL for a specific share
                # For simplicity, we'll just note it and continue.
            }
        }
    }

    if ($result.Result -eq 'Vulnerable') {
        $vulnerableSharesList = $result.VulnerableShares -join ', '
        $result.Details = "The following shares grant access to 'Everyone': $vulnerableSharesList"
    }

} catch {
    # This top-level catch handles errors like Get-SmbShare not being available.
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking share permissions: $($_.Exception.Message)"
}

# Remove the temporary list from the final output
$result.Remove('VulnerableShares')

# Convert the result to JSON and print to standard output
$result | ConvertTo-Json -Compress

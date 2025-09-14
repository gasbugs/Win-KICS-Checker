<#
.SYNOPSIS
    Checks if user home directory permissions are set appropriately (no 'Everyone' access).

.DESCRIPTION
    This script iterates through user home directories and verifies their Access Control Lists (ACLs).
    It ensures that 'Everyone' has no access permissions to these directories, excluding 'All Users' and 'Default User' directories.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W76UserHomeDirectoryPermissions {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-76"
    $category = "Security Management"
    $result = "Good"
    $details = @()

    try {
        $userProfiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.LocalPath -ne $null }

        foreach ($profile in $userProfiles) {
            $homeDir = $profile.LocalPath
            # Corrected userName assignment for literal backslash
            $userName = $profile.PSComputerName + "\" + $profile.Sid.AccountDomainSid.Value # Attempt to get full username
            if ($profile.Sid.AccountDomainSid -eq $null) { # Local account
                $userName = $profile.PSComputerName + "\" + $profile.Sid.Value
            }

            # Exclude All Users and Default User directories as per guide
            if ($homeDir -like "*\All Users" -or $homeDir -like "*\Default User" -or $homeDir -like "*\Public") {
                $details += "Skipping excluded directory: $homeDir. "
                continue
            }

            if (Test-Path $homeDir) {
                $acl = Get-Acl -Path $homeDir -ErrorAction SilentlyContinue
                $everyoneAccess = $false

                foreach ($access in $acl.Access) {
                    if ($access.IdentityReference.Value -eq "S-1-1-0" -or $access.IdentityReference.Value -eq "Everyone") { # S-1-1-0 is the SID for Everyone
                        $everyoneAccess = $true
                        break
                    }
                }

                if ($everyoneAccess) {
                    $result = "Vulnerable"
                    $details += "Home directory '$homeDir' for user '$userName' has 'Everyone' access permissions. "
                } else {
                    $details += "Home directory '$homeDir' for user '$userName' does not have 'Everyone' access permissions. "
                }
            } else {
                $result = "Error"
                $details += "Home directory '$homeDir' for user '$userName' not found. Cannot check permissions. "
            }
        }

        if ($result -eq "Good") {
            $details = "All checked user home directories do not have 'Everyone' access permissions. " + ($details -join [Environment]::NewLine)
        } elseif ($details.Count -gt 0) {
            $details = "Some user home directories have 'Everyone' access permissions: " + ($details -join [Environment]::NewLine)
        } else {
            $result = "Good"
            $details = "No user home directories found to check (excluding All Users, Default User, Public)."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking user home directory permissions: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W76UserHomeDirectoryPermissions
<#
.SYNOPSIS
    Checks if remote access to event log files is blocked by restricting 'Everyone' permissions.

.DESCRIPTION
    This script verifies the Access Control Lists (ACLs) of critical event log directories.
    It checks if the 'Everyone' group has access permissions to these directories,
    which would allow unauthorized remote access to log files.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W71BlockRemoteEventLogAccess {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-71"
    $category = "Log Management"
    $result = "Good"
    $details = @()

    $logDirs = @(
        "$env:SystemRoot\System32\config", # System logs
        "$env:SystemRoot\System32\LogFiles" # IIS logs, etc.
    )

    try {
        foreach ($dir in $logDirs) {
            if (Test-Path $dir) {
                $acl = Get-Acl -Path $dir -ErrorAction SilentlyContinue
                $everyoneAccess = $false

                foreach ($access in $acl.Access) {
                    if ($access.IdentityReference.Value -eq "S-1-1-0" -or $access.IdentityReference.Value -eq "Everyone") { # S-1-1-0 is the SID for Everyone
                        $everyoneAccess = $true
                        break
                    }
                }

                if ($everyoneAccess) {
                    $result = "Vulnerable"
                    $details += "Directory '$dir' has 'Everyone' access permissions. "
                } else {
                    $details += "Directory '$dir' does not have 'Everyone' access permissions. "
                }
            } else {
                $result = "Error"
                $details += "Directory '$dir' not found. Cannot check permissions. "
            }
        }

        if ($result -eq "Good") {
            $details = "All checked log directories do not have 'Everyone' access permissions." + [Environment]::NewLine + ($details -join [Environment]::NewLine)
        } else {
            $details = "Some log directories have 'Everyone' access permissions." + [Environment]::NewLine + ($details -join [Environment]::NewLine)
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking remote event log access: $($_.Exception.Message)"
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
Test-W71BlockRemoteEventLogAccess
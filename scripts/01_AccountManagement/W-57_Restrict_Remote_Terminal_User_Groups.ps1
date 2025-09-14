<#
.SYNOPSIS
    Checks the members of the 'Remote Desktop Users' group.

.DESCRIPTION
    This script lists the members of the 'Remote Desktop Users' group.
    The policy recommends restricting remote terminal access to only necessary accounts.
    If members other than the built-in Administrator are present, manual review is required
    to ensure they are authorized and follow the principle of least privilege.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including group members.
#>

function Test-W57RestrictRemoteTerminalUserGroups {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-57"
    $category = "Account Management"
    $result = "Good"
    $details = ""
    $groupName = "Remote Desktop Users"
    $groupMembers = @()

    try {
        $group = Get-LocalGroup -Name $groupName -ErrorAction SilentlyContinue

        if ($group) {
            $members = Get-LocalGroupMember -Group $groupName -ErrorAction SilentlyContinue
            if ($members) {
                foreach ($member in $members) {
                    $groupMembers += @{
                        Name = $member.Name
                        SID = $member.SID.Value
                        PrincipalSource = $member.PrincipalSource
                        ObjectClass = $member.ObjectClass
                    }
                }
            }

            # Check if there are members other than the built-in Administrator
            # The built-in Administrator has SID ending in -500
            $nonAdministratorMembers = $groupMembers | Where-Object { $_.SID -notlike "*-500" }

            if ($nonAdministratorMembers.Count -eq 0) {
                $details = "The 'Remote Desktop Users' group contains only the built-in Administrator account or is empty."
            } else {
                $result = "Manual Check Required"
                $details = "The 'Remote Desktop Users' group contains members other than the built-in Administrator. Manual review is required to ensure these accounts are authorized and necessary for remote access."
            }
        } else {
            $result = "Error"
            $details = "Group '$groupName' not found."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking 'Remote Desktop Users' group: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        GroupMembers = $groupMembers # Include group members for manual review
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W57RestrictRemoteTerminalUserGroups

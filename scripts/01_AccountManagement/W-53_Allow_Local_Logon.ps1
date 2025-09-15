<#
.SYNOPSIS
    Checks if the 'Allow log on locally' policy is restricted to Administrators.

.DESCRIPTION
    This script verifies the 'Allow log on locally' user rights assignment.
    It ensures that only the 'Administrators' group is granted this right, preventing unauthorized local logons.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including assigned users/groups.
#>

function Test-W53AllowLocalLogon {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-53"
    $category = "Account Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile  /quiet # Removed /areas SECURITYPOLICY
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $seInteractiveLogonRightLine = $content | Select-String -Pattern "SeInteractiveLogonRight = "
        if ($seInteractiveLogonRightLine) {
            $assignedSids = $seInteractiveLogonRightLine.ToString().Split('=')[1].Trim().Split(',')
            $assignedNames = @()

            foreach ($sid in $assignedSids) {
                try {
                    $assignedNames += (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
                } catch {
                    $assignedNames += $sid # Keep SID if translation fails
                }
            }

            $unnecessaryAccounts = @()
            # Check for SIDs that are not Administrators (S-1-5-32-544)
            # Assuming only Administrators should have this right
            foreach ($sid in $assignedSids) {
                if (-not ($sid -eq "*S-1-5-32-544")) { # Check against Administrators SID
                    $unnecessaryAccounts += $sid # Add SID if it's not Administrators
                }
            }

            if ($unnecessaryAccounts.Count -eq 0) {
                $details = "Only Administrators are allowed to log on locally. Assigned: $($assignedNames -join ', ')."
            } else {
                $result = "Vulnerable"
                $details = "Unnecessary accounts/groups are allowed to log on locally. Assigned: $($assignedNames -join ', '). Unnecessary: $($unnecessaryAccounts -join ', ')."
            }
        } else {
            $result = "Vulnerable"
            $details = "'Allow log on locally' policy (SeInteractiveLogonRight) not found in security policy export."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking local logon policy: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        AssignedUsers = $assignedNames # Include assigned users for review
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W53AllowLocalLogon
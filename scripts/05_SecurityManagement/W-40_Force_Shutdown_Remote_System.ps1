<#
.SYNOPSIS
    Checks if the 'Force shutdown from a remote system' policy only contains Administrators.

.DESCRIPTION
    This script verifies the 'Force shutdown from a remote system' user rights assignment.
    It ensures that only the 'Administrators' group is granted this right, preventing unauthorized remote shutdowns.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including assigned users/groups.
#>

function Test-W40ForceShutdownRemoteSystem {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-40"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $seRemoteShutdownPrivilegeLine = $content | Select-String -Pattern "SeRemoteShutdownPrivilege = "
        if ($seRemoteShutdownPrivilegeLine) {
            $assignedSids = $seRemoteShutdownPrivilegeLine.ToString().Split('=')[1].Trim().Split(',')
            $assignedNames = @()

            foreach ($sid in $assignedSids) {
                try {
                    $assignedNames += (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
                } catch {
                    $assignedNames += $sid # Keep SID if translation fails
                }
            }

            $unnecessaryAccounts = @()
            foreach ($name in $assignedNames) {
                if (-not ($name -like "*\Administrators")) {
                    $unnecessaryAccounts += $name
                }
            }

            if ($unnecessaryAccounts.Count -eq 0) {
                $details = "Only Administrators are allowed to force shutdown from a remote system. Assigned: $($assignedNames -join ', ')."
            } else {
                $result = "Vulnerable"
                $details = "Unnecessary accounts/groups are allowed to force shutdown from a remote system. Assigned: $($assignedNames -join ', '). Unnecessary: $($unnecessaryAccounts -join ', ')."
            }
        } else {
            $result = "Vulnerable"
            $details = "'Force shutdown from a remote system' policy (SeRemoteShutdownPrivilege) not found in security policy export."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking remote shutdown policy: $($_.Exception.Message)"
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
Test-W40ForceShutdownRemoteSystem

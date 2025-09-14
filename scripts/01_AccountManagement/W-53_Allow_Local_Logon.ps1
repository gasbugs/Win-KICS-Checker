<#
.SYNOPSIS
    Checks if the 'Allow log on locally' policy only contains Administrators and IUSR_ (if applicable).

.DESCRIPTION
    This script verifies the 'Allow log on locally' user rights assignment.
    It ensures that only necessary accounts like 'Administrators' and 'IUSR_' (for IIS) are granted this right.
    Presence of other accounts or groups can increase the attack surface.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
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
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
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
                    # Handle cases where SID might not translate (e.g., well-known SIDs not directly translatable to NTAccount)
                    $assignedNames += $sid # Keep SID if translation fails
                }
            }

            $unnecessaryAccounts = @()
            foreach ($name in $assignedNames) {
                # Check for Administrators group (localized name might vary)
                # Check for IUSR_ (IIS user, might vary)
                # This check is simplified and might need refinement for all possible localized names or specific IUSR_ patterns.
                if (-not ($name -like "*\Administrators" -or $name -like "*\IUSR_*")) {
                    $unnecessaryAccounts += $name
                }
            }

            if ($unnecessaryAccounts.Count -eq 0) {
                $details = "Only Administrators and IUSR_ (if applicable) are allowed to log on locally. Assigned: $($assignedNames -join ', ')."
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
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W53AllowLocalLogon

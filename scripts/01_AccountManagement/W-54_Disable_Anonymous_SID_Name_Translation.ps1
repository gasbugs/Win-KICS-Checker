<#
.SYNOPSIS
    Checks if the 'Network access: Allow anonymous SID/name translation' policy is disabled.

.DESCRIPTION
    This script verifies if the security policy 'Network access: Allow anonymous SID/name translation'
    is set to 'Disabled'. This prevents anonymous users from translating SIDs to names and vice versa,
    reducing information disclosure.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W54DisableAnonymousSIDNameTranslation {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-54"
    $category = "Account Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $lsaAnonymousNameLookup = ($content | Select-String -Pattern "LSAAnonymousNameLookup" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($lsaAnonymousNameLookup -eq 0) {
            $details = "The 'Network access: Allow anonymous SID/name translation' policy is disabled."
        } else {
            $result = "Vulnerable"
            $details = "The 'Network access: Allow anonymous SID/name translation' policy is enabled (Current value: $lsaAnonymousNameLookup)."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking the policy: $($_.Exception.Message)"
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
Test-W54DisableAnonymousSIDNameTranslation

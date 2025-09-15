<#
.SYNOPSIS
    Checks if the 'Audit: Shut down system immediately if unable to log security audits' policy is disabled.

.DESCRIPTION
    This script verifies if the security policy 'Audit: Shut down system immediately if unable to log security audits'
    is set to 'Disabled'. Enabling this policy can lead to denial-of-service if the security log becomes full.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W41DisableImmediateShutdownAuditFailure {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-41"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /quiet # Removed /areas SECURITYPOLICY as per user's last instruction
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $crashOnAuditFail = ($content | Select-String -Pattern "CrashOnAuditFail" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($crashOnAuditFail -eq 0) {
            $details = "The 'Audit: Shut down system immediately if unable to log security audits' policy is disabled."
        } else {
            $result = "Vulnerable"
            $details = "The 'Audit: Shut down system immediately if unable to log security audits' policy is enabled (Current value: $crashOnAuditFail)."
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
Test-W41DisableImmediateShutdownAuditFailure

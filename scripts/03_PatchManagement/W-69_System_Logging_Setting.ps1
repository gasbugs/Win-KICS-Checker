<#
.SYNOPSIS
    Checks if system logging (Security event log) is configured according to policy.

.DESCRIPTION
    This script verifies the configuration of the 'Security' event log, including its maximum size and retention policy.
    Detailed audit policy settings (e.g., Logon/Logoff, Account Management) are complex and require manual review
    via Group Policy Editor (GPEDIT.MSC) or Local Security Policy (SECPOL.MSC).

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W69SystemLoggingSetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-69"
    $category = "Patch Management"
    $result = "Manual Check Required"
    $details = ""

    try {
        $securityLog = Get-WinEvent -ListLog Security -ErrorAction SilentlyContinue

        if ($securityLog) {
            $maxSizeMB = $securityLog.MaximumSizeInBytes / 1MB
            $retention = $securityLog.LogMode

            $details = "Security event log configuration: `n"
            $details += "  - Maximum Size: $($maxSizeMB) MB`n"
            $details += "  - Retention Policy: $retention`n"
            $details += "Detailed audit policy settings require manual verification (SECPOL.MSC or GPEDIT.MSC)."
        } else {
            $result = "Error"
            $details = "Security event log not found or accessible."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking system logging settings: $($_.Exception.Message)"
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
Test-W69SystemLoggingSetting

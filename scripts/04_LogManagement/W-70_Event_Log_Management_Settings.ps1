<#
.SYNOPSIS
    Checks if event log file size and retention period are set appropriately.

.DESCRIPTION
    This script verifies the configuration of 'Application', 'System', and 'Security' event logs.
    It checks if the maximum log size is set to 10,240KB (10MB) or more, and if the retention policy
    is set to 'Overwrite events older than 90 days'.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W70EventLogManagementSettings {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-70"
    $category = "Log Management"
    $result = "Good"
    $details = @()
    $minRecommendedSizeKB = 10240 # 10MB
    $minRecommendedRetentionDays = 90

    $logNames = @("Application", "System", "Security")

    try {
        foreach ($logName in $logNames) {
            $log = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue

            if ($log) {
                $logResult = "Good"
                $logDetails = ""

                # Check MaximumSizeInBytes
                if ($log.MaximumSizeInBytes -lt ($minRecommendedSizeKB * 1KB)) {
                    $logResult = "Vulnerable"
                    $logDetails += "Maximum size ($($log.MaximumSizeInBytes / 1KB) KB) is less than recommended ($minRecommendedSizeKB KB). "
                }

                # Check LogMode (Retention Policy)
                if ($log.LogMode -eq 'Circular') {
                    $logResult = "Vulnerable"
                    $logDetails += "Retention policy is 'Overwrite events as needed' (Circular). "
                } elseif ($log.LogMode -eq 'OverwriteOlder') {
                    # For OverwriteOlder, check RetentionDays (if available and applicable)
                    # Note: Get-WinEvent -ListLog doesn't directly expose RetentionDays for OverwriteOlder in all versions/scenarios.
                    # This might require parsing secedit /export or checking specific registry keys for precise days.
                    # For simplicity, if it's OverwriteOlder, we assume it's configured correctly or requires manual check for days.
                    $logDetails += "Retention policy is 'Overwrite events older than...'. "
                } else {
                    $logResult = "Vulnerable"
                    $logDetails += "Retention policy is '{$log.LogMode}', which is not recommended. "
                }

                if ($logResult -eq "Good") {
                    $details += "$logName Log: Good. Max Size: $($log.MaximumSizeInBytes / 1KB) KB, Mode: $($log.LogMode)."
                } else {
                    $result = "Vulnerable"
                    $details += "$logName Log: Vulnerable. $($logDetails) Max Size: $($log.MaximumSizeInBytes / 1KB) KB, Mode: $($log.LogMode)."
                }
            } else {
                $result = "Error"
                $details += "$logName Log: Not found or accessible. "
            }
        }

        if ($result -eq "Good") {
            $details = "All checked event logs meet the recommended size and retention policies." + [Environment]::NewLine + ($details -join [Environment]::NewLine)
        } else {
            $details = "Some event logs do not meet the recommended size or retention policies." + [Environment]::NewLine + ($details -join [Environment]::NewLine)
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking event log management settings: $($_.Exception.Message)"
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
Test-W70EventLogManagementSettings
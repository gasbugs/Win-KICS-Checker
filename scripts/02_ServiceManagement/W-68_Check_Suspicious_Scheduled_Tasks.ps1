<#
.SYNOPSIS
    Checks for suspicious commands registered in scheduled tasks.

.DESCRIPTION
    This script lists all scheduled tasks on the system.
    Determining if a task is 'suspicious' requires human intelligence and context-specific knowledge.
    Therefore, this check reports all scheduled tasks and requires manual review to identify and remove any unnecessary or malicious ones.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details, including a list of scheduled tasks.
#>

function Test-W68CheckSuspiciousScheduledTasks {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-68"
    $category = "Service Management"
    $result = "Manual Check Required"
    $details = "Review the list of scheduled tasks to identify and remove any unnecessary or suspicious ones."
    $scheduledTasks = @()

    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue

        if ($tasks) {
            foreach ($task in $tasks) {
                $scheduledTasks += @{
                    TaskName = $task.TaskName
                    State = $task.State
                    Actions = if ($task.Actions) { ($task.Actions | ForEach-Object { if ($_ -ne $null) { $_.ToString() } else { "" } }) -join '; ' } else { "" }
                    Triggers = if ($task.Triggers) { ($task.Triggers | ForEach-Object { if ($_ -ne $null) { $_.ToString() } else { "" } }) -join '; ' } else { "" }
                    Author = $task.Author
                    LastRunTime = $task.LastRunTime
                    LastTaskResult = $task.LastTaskResult
                }
            }
        }

        if ($scheduledTasks.Count -eq 0) {
            $details = "No scheduled tasks found. (Good)"
            $result = "Good"
        } else {
            $details = "The following scheduled tasks were found. Manual review is required to identify and remove any unnecessary or suspicious ones.`n" + ($scheduledTasks | Out-String)
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking scheduled tasks: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        ScheduledTasks = $scheduledTasks # Include task details for manual review
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W68CheckSuspiciousScheduledTasks

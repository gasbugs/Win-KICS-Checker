# W-37: 예약된 작업에 의심스러운 명령이 등록되어 있는지 점검
function Test-W37 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem      = "W-37"
        Category       = "서비스 관리"
        Result         = "Good"
        Details        = ""
        ScheduledTasks = @()
        Timestamp      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object { $_.State -ne 'Disabled' }

        if (-not $tasks -or $tasks.Count -eq 0) {
            $result.Details = "No active scheduled tasks found."
            $result | ConvertTo-Json -Depth 4
            return
        }

        foreach ($task in $tasks) {
            $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
            $actions = $task.Actions | ForEach-Object {
                "$($_.Execute) $($_.Arguments)"
            }

            $result.ScheduledTasks += @{
                TaskName       = $task.TaskName
                TaskPath       = $task.TaskPath
                State          = "$($task.State)"
                Actions        = $actions
                Author         = $task.Author
                LastRunTime    = "$($taskInfo.LastRunTime)"
                LastTaskResult = $taskInfo.LastTaskResult
            }
        }

        $result.Result  = "Manual Check Required"
        $result.Details = "Found $($tasks.Count) active scheduled task(s). Review for suspicious commands."
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking scheduled tasks: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W37

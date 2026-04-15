# W-11: 로컬 로그온 허용
function Test-W11 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem     = "W-11"
        Category      = "계정 관리"
        Result        = "Good"
        Details       = ""
        AssignedUsers = @()
        Timestamp     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $logonRightLine = $content | Select-String -Pattern "SeInteractiveLogonRight = "

        if ($logonRightLine) {
            $assignedSids = $logonRightLine.ToString().Split('=')[1].Trim().Split(',')
            $assignedNames = @()

            foreach ($sid in $assignedSids) {
                $sid = $sid.Trim().TrimStart('*')
                try {
                    $assignedNames += (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
                } catch {
                    $assignedNames += $sid
                }
            }

            $result.AssignedUsers = $assignedNames

            # S-1-5-32-544 = Administrators
            $unnecessaryAccounts = $assignedSids | Where-Object { $_.Trim() -ne "*S-1-5-32-544" }

            if ($unnecessaryAccounts.Count -eq 0) {
                $result.Details = "Only Administrators are allowed to log on locally. Assigned: $($assignedNames -join ', ')."
            } else {
                $result.Result  = "Vulnerable"
                $result.Details = "Non-administrator accounts are allowed to log on locally. Assigned: $($assignedNames -join ', ')."
            }
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "'Allow log on locally' policy (SeInteractiveLogonRight) not found in security policy export."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking local logon policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W11

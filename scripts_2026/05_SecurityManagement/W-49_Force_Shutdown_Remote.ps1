# W-49: 원격 시스템에서 강제로 시스템 종료
function Test-W49 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem     = "W-49"
        Category      = "보안 관리"
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

        $line = $content | Select-String -Pattern "SeRemoteShutdownPrivilege = "

        if ($line) {
            $sids = $line.ToString().Split('=')[1].Trim().Split(',')
            $names = @()
            foreach ($sid in $sids) {
                $sid = $sid.Trim().TrimStart('*')
                try {
                    $names += (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
                } catch { $names += $sid }
            }
            $result.AssignedUsers = $names

            $nonAdmin = $sids | Where-Object { $_.Trim() -ne "*S-1-5-32-544" }
            if ($nonAdmin.Count -eq 0) {
                $result.Details = "Only Administrators can force remote shutdown. Assigned: $($names -join ', ')."
            } else {
                $result.Result  = "Vulnerable"
                $result.Details = "Non-administrator accounts can force remote shutdown. Assigned: $($names -join ', ')."
            }
        } else {
            $result.Details = "SeRemoteShutdownPrivilege not found in policy. Default (Administrators only) is applied."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking remote shutdown privilege: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W49

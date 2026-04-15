# W-16: 공유 권한 및 사용자 그룹 설정
function Test-W16 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-16"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $shares = Get-SmbShare -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '\$$' -and $_.Name -ne 'IPC$' }

        if (-not $shares) {
            $result.Details = "No non-administrative shares found."
            $result | ConvertTo-Json -Depth 4
            return
        }

        $vulnerableShares = @()
        foreach ($share in $shares) {
            $acl = Get-SmbShareAccess -Name $share.Name -ErrorAction SilentlyContinue
            $everyoneAccess = $acl | Where-Object { $_.AccountName -eq 'Everyone' }
            if ($everyoneAccess) {
                $vulnerableShares += "$($share.Name) (Everyone: $($everyoneAccess.AccessRight -join ','))"
            }
        }

        if ($vulnerableShares.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Shares with 'Everyone' access: $($vulnerableShares -join '; ')"
        } else {
            $result.Details = "No shares grant access to 'Everyone'. Total shares checked: $($shares.Count)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking share permissions: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W16

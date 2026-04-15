# W-58: 사용자별 홈 디렉터리 권한 설정
function Test-W58 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-58"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $profiles = Get-CimInstance -Class Win32_UserProfile -ErrorAction SilentlyContinue |
            Where-Object { -not $_.Special -and $_.LocalPath }
        $issues = @()

        foreach ($profile in $profiles) {
            $path = $profile.LocalPath
            if (-not (Test-Path $path)) { continue }

            $acl = Get-Acl $path -ErrorAction SilentlyContinue
            foreach ($ace in $acl.Access) {
                if ($ace.IdentityReference.Value -eq 'Everyone') {
                    $issues += "${path}: Everyone has $($ace.FileSystemRights)"
                }
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Home directories with 'Everyone' access: $($issues -join '; ')"
        } else {
            $result.Details = "No user home directories grant access to 'Everyone'."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking home directory permissions: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W58

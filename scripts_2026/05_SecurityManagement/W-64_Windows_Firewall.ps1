# W-64: 윈도우 방화벽 설정 (신규 항목)
function Test-W64 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-64"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $profiles = Get-NetFirewallProfile -ErrorAction Stop
        $disabledProfiles = @()

        foreach ($profile in $profiles) {
            if (-not $profile.Enabled) {
                $disabledProfiles += $profile.Name
            }
        }

        if ($disabledProfiles.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Windows Firewall is disabled on profile(s): $($disabledProfiles -join ', ')."
        } else {
            $profileInfo = ($profiles | ForEach-Object { "$($_.Name): Enabled" }) -join ', '
            $result.Details = "Windows Firewall is enabled on all profiles ($profileInfo)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking Windows Firewall: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W64

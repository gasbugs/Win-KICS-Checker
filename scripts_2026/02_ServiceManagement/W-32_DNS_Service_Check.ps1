# W-32: DNS 서비스 구동 점검
function Test-W32 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-32"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $dnsSvc = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
        if (-not $dnsSvc -or $dnsSvc.Status -ne 'Running') {
            $result.Result  = "Not Applicable"
            $result.Details = "DNS service is not running."
            $result | ConvertTo-Json -Depth 4
            return
        }

        Import-Module DnsServer -ErrorAction Stop
        $zones = Get-DnsServerZone -ErrorAction SilentlyContinue |
            Where-Object { $_.ZoneType -eq 'Primary' }
        $vulnerableZones = @()

        foreach ($zone in $zones) {
            if ($zone.DynamicUpdate -ne 'None') {
                $vulnerableZones += "$($zone.ZoneName) (DynamicUpdate: $($zone.DynamicUpdate))"
            }
        }

        if ($vulnerableZones.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "DNS dynamic updates enabled on: $($vulnerableZones -join '; ')"
        } else {
            $result.Details = "DNS dynamic updates are disabled on all primary zones."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking DNS service: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W32

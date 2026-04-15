# W-25: DNS Zone Transfer 설정
function Test-W25 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-25"
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
            # SecureSecondaries: 1=ToAnyServer(취약), 0=None, 2=ToNsServers, 3=ToSpecificServers
            if ($zone.SecureSecondaries -eq 1) {
                $vulnerableZones += "$($zone.ZoneName) (Zone transfer allowed to any server)"
            }
        }

        if ($vulnerableZones.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "DNS zone transfer is unrestricted on: $($vulnerableZones -join '; ')"
        } else {
            $result.Details = "DNS zone transfer is properly restricted on all primary zones."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking DNS zone transfer: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W25

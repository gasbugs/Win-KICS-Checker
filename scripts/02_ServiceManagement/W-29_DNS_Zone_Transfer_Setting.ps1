# W-29_DNS_Zone_Transfer_Setting.ps1
# Checks whether DNS Zone Transfer is blocked.

function Test-DNSZoneTransferSetting {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-29"
        Category = "Service Management"
        Result = "Good" # Default to Good
        Details = ""
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    try {
        # Check if DNS Server service is running
        $dnsService = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
        if (-not $dnsService -or $dnsService.Status -ne "Running") {
            $result.Details = "DNS Server service is not running. This check is not applicable."
            return $result
        }

        # Requires DnsServer module for Get-DnsServerZoneTransferPolicy
        if (-not (Get-Module -ListAvailable -Name DnsServer -ErrorAction SilentlyContinue)) {
            $result.Result = "Manual Check Required"
            $result.Details = "DnsServer module not available. Manual check required for DNS Zone Transfer settings."
            return $result
        }
        Import-Module DnsServer -ErrorAction Stop

        $zones = Get-DnsServerZone -ErrorAction SilentlyContinue
        if (-not $zones) {
            $result.Details = "No DNS zones found. This check is not applicable."
            return $result
        }

        $vulnerableZones = @()
        foreach ($zone in $zones) {
            # Check Zone Transfer settings
            # AllowZoneTransfer: 0 (None), 1 (To any server), 2 (To servers listed in NS records), 3 (To specific servers)
            if ($zone.AllowZoneTransfer -eq 1) { # "To any server" is vulnerable
                $vulnerableZones += $zone.ZoneName
            }
        }

        if ($vulnerableZones.Count -gt 0) {
            $result.Result = "Vulnerable"
            $result.Details = "DNS Zone Transfer is allowed to any server on the following zones: $($vulnerableZones -join ', '). It should be restricted."
        } else {
            $result.Result = "Good"
            $result.Details = "DNS Zone Transfer is restricted or disabled on all detected DNS zones."
        }

    } catch {
        $result.Result = "Error"
        $result.Details = "An error occurred while checking DNS Zone Transfer settings: $($_.Exception.Message)"
    }

    return $result
}

Test-DNSZoneTransferSetting | ConvertTo-Json -Depth 100
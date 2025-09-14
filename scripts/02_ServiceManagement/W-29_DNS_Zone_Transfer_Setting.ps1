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
        $manualCheckZones = @()
        $manualCheckDetails = @()

        foreach ($zone in $zones) {
            # Check Zone Transfer settings using SecureSecondaries property
            # SecureSecondaries: 0 (None), 1 (ToAnyServer), 2 (ToServersListedInNsRecords), 3 (ToSpecificServers)
            # Also check for the string "TransferAnyServer" if it's set directly
            if ($zone.SecureSecondaries -eq 1 -or $zone.SecureSecondaries -eq "TransferAnyServer") { # ToAnyServer is vulnerable
                $vulnerableZones += $zone.ZoneName
            } elseif ($zone.SecureSecondaries -eq 3) { # ToSpecificServers
                if (-not $zone.SecureSecondaries -or $zone.SecureSecondaries.Count -eq 0) {
                    # This condition is unlikely to be met if SecureSecondaries is 3, as it implies specific servers are listed.
                    # However, if it means no specific IPs are listed, it's not vulnerable.
                } else {
                    # Specific secondaries are listed, requires manual review to ensure they are authorized
                    $manualCheckZones += $zone.ZoneName
                    $manualCheckDetails += "Zone $($zone.ZoneName) allows zone transfer to specific servers: $($zone.SecureSecondaries -join ', '). Manual review required."
                }
            }
            # SecureSecondaries -eq 0 (None) and -eq 2 (ToServersListedInNsRecords) are considered good/secure by default
        }

        if ($vulnerableZones.Count -gt 0) {
            $result.Result = "Vulnerable"
            $result.Details = "DNS Zone Transfer is allowed to any server on the following zones: $($vulnerableZones -join ', '). It should be restricted."
        } elseif ($manualCheckZones.Count -gt 0) {
            $result.Result = "Manual Check Required"
            $result.Details = ($manualCheckDetails -join "`n")
        }
         else {
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
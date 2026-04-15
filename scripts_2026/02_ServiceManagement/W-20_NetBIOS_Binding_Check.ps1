# W-20: NetBIOS 바인딩 서비스 구동 점검
function Test-W20 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-20"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "TcpipNetbiosOptions IS NOT NULL AND IPEnabled=True" -ErrorAction SilentlyContinue
        $vulnerableAdapters = @()

        foreach ($adapter in $adapters) {
            # TcpipNetbiosOptions: 0=DHCP, 1=Enable, 2=Disable
            if ($adapter.TcpipNetbiosOptions -ne 2) {
                $statusText = switch ($adapter.TcpipNetbiosOptions) {
                    0 { "Use DHCP setting" }
                    1 { "Enabled" }
                    default { "Unknown ($($adapter.TcpipNetbiosOptions))" }
                }
                $vulnerableAdapters += "$($adapter.Description): NetBIOS=$statusText"
            }
        }

        if ($vulnerableAdapters.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "NetBIOS over TCP/IP is not disabled on: $($vulnerableAdapters -join '; ')"
        } else {
            $result.Details = "NetBIOS over TCP/IP is disabled on all network adapters."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking NetBIOS binding: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W20

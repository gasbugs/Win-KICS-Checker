# W-24_NetBIOS_Binding_Service_Operation_Check.ps1
# Checks whether NetBIOS over TCP/IP binding is removed.

function Test-NetBIOSBindingServiceOperationCheck {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-24"
        Category = "Service Management"
        Result = "Good" # Default to Good
        Details = ""
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    try {
        # Get all network adapters that are bound to TCP/IP
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }

        $isVulnerable = $false
        $vulnerableAdapters = @()

        foreach ($adapter in $adapters) {
            # Check if NetBIOS over TCP/IP is enabled for the adapter
            # This is typically controlled by the TcpipNetbiosOptions property:
            # 0 = Use NetBIOS setting from the DHCP server
            # 1 = Enable NetBIOS over TCP/IP
            # 2 = Disable NetBIOS over TCP/IP
            if ($adapter.TcpipNetbiosOptions -eq 0 -or $adapter.TcpipNetbiosOptions -eq 1) {
                $isVulnerable = $true
                $vulnerableAdapters += $adapter.Description
            }
        }

        if ($isVulnerable) {
            $result.Result = "Vulnerable"
            $result.Details = "NetBIOS over TCP/IP binding is enabled on the following adapters: $($vulnerableAdapters -join ', '). It should be disabled."
        } else {
            $result.Result = "Good"
            $result.Details = "NetBIOS over TCP/IP binding is disabled on all TCP/IP enabled adapters."
        }

    } catch {
        $result.Result = "Error"
        $result.Details = "An error occurred while checking NetBIOS binding: $($_.Exception.Message)"
    }

    return $result
}

Test-NetBIOSBindingServiceOperationCheck | ConvertTo-Json -Depth 100
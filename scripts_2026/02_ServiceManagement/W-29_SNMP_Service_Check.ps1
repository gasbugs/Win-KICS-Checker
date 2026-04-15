# W-29: 불필요한 SNMP 서비스 구동 점검
function Test-W29 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-29"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue

        if ($snmpSvc -and $snmpSvc.Status -eq 'Running') {
            $result.Result  = "Vulnerable"
            $result.Details = "SNMP service is running. Disable if not required."
        } elseif ($snmpSvc) {
            $result.Details = "SNMP service is installed but not running (Status: $($snmpSvc.Status))."
        } else {
            $result.Details = "SNMP service is not installed."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking SNMP service: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W29

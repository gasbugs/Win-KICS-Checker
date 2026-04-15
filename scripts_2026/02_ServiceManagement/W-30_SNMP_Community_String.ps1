# W-30: SNMP Community String 복잡성 설정
function Test-W30 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-30"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $snmpSvc = Get-Service -Name "SNMP" -ErrorAction SilentlyContinue
        if (-not $snmpSvc) {
            $result.Result  = "Not Applicable"
            $result.Details = "SNMP service is not installed."
            $result | ConvertTo-Json -Depth 4
            return
        }

        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
        if (-not (Test-Path $regPath)) {
            $result.Details = "No SNMP community strings configured."
            $result | ConvertTo-Json -Depth 4
            return
        }

        $communities = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).PSObject.Properties |
            Where-Object { $_.Name -notlike 'PS*' } |
            ForEach-Object { $_.Name }

        $weakStrings = $communities | Where-Object { $_ -match '^(public|private)$' }

        if ($weakStrings) {
            $result.Result  = "Vulnerable"
            $result.Details = "Weak SNMP community strings found: $($weakStrings -join ', '). All strings: $($communities -join ', ')."
        } else {
            $result.Details = "SNMP community strings are complex. Configured: $($communities -join ', ')."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking SNMP community strings: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W30

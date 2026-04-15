# W-31: SNMP Access control 설정
function Test-W31 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-31"
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

        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"

        if (-not (Test-Path $regPath)) {
            $result.Result  = "Vulnerable"
            $result.Details = "SNMP PermittedManagers registry key not found. Access is not restricted."
            $result | ConvertTo-Json -Depth 4
            return
        }

        $managers = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).PSObject.Properties |
            Where-Object { $_.Name -notlike 'PS*' }

        if ($managers.Count -eq 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "SNMP PermittedManagers is empty. Access is not restricted."
        } else {
            $managerList = ($managers | ForEach-Object { $_.Value }) -join ', '
            $result.Details = "SNMP access is restricted to: $managerList."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking SNMP access control: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W31

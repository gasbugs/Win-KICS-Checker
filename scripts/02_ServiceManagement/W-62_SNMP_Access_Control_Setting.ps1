<#
.SYNOPSIS
    Checks if SNMP access control is configured to accept packets only from specific hosts.

.DESCRIPTION
    This script verifies the SNMP service's access control settings.
    It checks if the 'PermittedManagers' registry key is configured with specific hosts,
    meaning SNMP packets are accepted only from those defined sources.
    If the key is missing or empty, it implies acceptance from any host, which is vulnerable.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W62SNMPAccessControlSetting {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-62"
    $category = "Service Management"
    $result = "Good"
    $details = ""

    try {
        $snmpService = Get-Service -Name SNMP -ErrorAction SilentlyContinue

        if (-not $snmpService) {
            $result = "Not Applicable"
            $details = "SNMP service is not installed. This check is not applicable."
        } elseif ($snmpService.Status -ne 'Running') {
            $details = "SNMP service is installed but not running. (Good)"
        } else {
            # SNMP service is running, check access control settings
            $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"

            # 1. 'PermittedManagers' 키가 존재하는지 확인
            if (Test-Path $registryPath) {
                # 2. 키가 존재하면, 등록된 IP 목록(속성)을 가져옴
                # PowerShell 자체 속성(PS*)을 제외하여 실제 IP 목록만 필터링
                $properties = Get-ItemProperty -Path $registryPath
                $allowed_ips = $properties.PSObject.Properties.Name | Where-Object { $_ -notmatch "^(PSPath|PSParentPath|PSChildName|PSDrive|PSProvider)$" }

                if ($null -eq $allowed_ips -or $allowed_ips.Count -eq 0) {
                    $result = "Vulnerable"
                    $details = "SNMP service is running and configured to accept packets from all hosts (PermittedManagers is not set or empty)."
                } else {
                    $details = "SNMP service is running and configured to accept packets only from specific hosts: $($allowed_ips -join ', ')."
                }
            } else {
                $result = "Vulnerable"
                $details = "SNMP service is running but 'PermittedManagers' registry path '$registryPath' not found. Cannot verify access control."
            }
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking SNMP access control: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W62SNMPAccessControlSetting

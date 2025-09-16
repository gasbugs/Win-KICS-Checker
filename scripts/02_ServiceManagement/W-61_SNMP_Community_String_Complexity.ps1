<#
.SYNOPSIS
    Checks if the SNMP service community strings are not default (e.g., 'public', 'private').

.DESCRIPTION
    This script verifies the status of the SNMP service and, if running,
    checks its configured community strings. Default community strings like 'public' or 'private'
    are considered vulnerable as they are widely known.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W61SNMPCommunityStringComplexity {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-61"
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
            # SNMP service is running, check community strings
            $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
            if (Test-Path $registryPath) {
                # 1. Get-Item으로 레지스트리 키 객체를 가져옵니다.
                $registryKey = Get-Item -Path $registryPath

                # 2. GetValueNames() 메서드를 사용해 값 이름들의 목록을 가져옵니다.
                $valueNames = $registryKey.GetValueNames()

                # 3. (Default) 값을 제외하고 출력합니다.
                $communityStrings = $valueNames | Where-Object { $_ -ne '(default)' }

                $vulnerableStrings = @("public", "private")
                $foundVulnerable = $false
                $foundStrings = @()

                foreach ($cs in $communityStrings) {
                    $foundStrings += $cs
                    if ($vulnerableStrings -contains $cs.ToLower()) {
                        $foundVulnerable = $true
                    }
                }

                if ($foundVulnerable) {
                    $result = "Vulnerable"
                    $details = "SNMP service is running and uses default or weak community strings: $($foundStrings -join ', ')."
                } else {
                    $details = "SNMP service is running and uses non-default community strings: $($foundStrings -join ', ')."
                }
            } else {
                $result = "Vulnerable"
                $details = "SNMP service is running but no community strings found in registry at '$registryPath'."
            }
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking SNMP community strings: $($_.Exception.Message)"
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
Test-W61SNMPCommunityStringComplexity

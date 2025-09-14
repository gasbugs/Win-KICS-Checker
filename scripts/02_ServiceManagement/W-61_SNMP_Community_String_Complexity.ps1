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
                $communityStrings = Get-ItemProperty -Path $registryPath | Select-Object -ExpandProperty PSObject | Select-Object -ExpandProperty Properties | Where-Object { $_.Name -ne '(default)' } | Select-Object -ExpandProperty Name

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

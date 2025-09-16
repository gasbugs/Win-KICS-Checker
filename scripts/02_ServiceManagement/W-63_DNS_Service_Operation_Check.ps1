<#
.SYNOPSIS
    Checks if the DNS Server service is running and if dynamic updates are disabled.

.DESCRIPTION
    This script verifies the status of the DNS Server service.
    According to the guideline, if the DNS service is not used or dynamic updates are disabled, it is considered good.
    If the DNS Server service is running, it indicates that dynamic update settings require manual verification
    due to the complexity of checking all DNS zones and their configurations.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W63DNSServiceOperationCheck {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-63"
    $category = "Service Management"
    $result = "Good"
    $details = ""

    try {
        # DNS 서버 역할이 설치되어 있는지 확인하고, 모든 주 영역(Primary Zone) 정보를 가져옵니다.
        # 동적 업데이트는 주 영역에서만 설정하므로 다른 유형의 영역은 제외합니다.
        $primaryZones = Get-DnsServerZone | Where-Object { $_.ZoneType -eq 'Primary' }
        
        # DNS 서비스가 설치되지 않았거나, 주 영역이 없는 경우 '양호'로 판단
        if (-not $primaryZones) {
            $details = "DNS server role is not installed or no Primary Zone is configured."
            Write-Host "[Diagnosis Result: Good ✅]" -ForegroundColor Green
            Write-Host "Reason: DNS server role is not installed or no Primary Zone is configured."
            Exit
        }

        # 주 영역 중에서 동적 업데이트 설정이 'None'(없음)이 아닌 영역을 찾습니다.
        $vulnerableZones = $primaryZones | Where-Object { $_.DynamicUpdate -ne 'None' }

        # 동적 업데이트가 설정된 영역이 하나라도 있는지 확인
        if ($vulnerableZones) {
            # 하나라도 있으면 '취약'
            $result = "Vulnerable"
            $details = "Dynamic updates are allowed in the following DNS zones:"
            Write-Host "[Diagnosis Result: Vulnerable 🚨]" -ForegroundColor Red
            Write-Host "Reason: Dynamic updates are allowed in the following DNS zones:"
            $vulnerableZones | ForEach-Object {
                Write-Host (" - Zone Name: {0}, Current Setting: {1}" -f $_.ZoneName, $_.DynamicUpdate)
            }
        } else {
            # 모두 'None'으로 설정되어 있으면 '양호'
            $details = "Dynamic updates for all DNS primary zones are correctly set to 'None'."
            Write-Host "[Diagnosis Result: Good ✅]" -ForegroundColor Green
            Write-Host "Dynamic updates for all DNS primary zones are correctly set to 'None'."
        }

    }
    catch [System.Management.Automation.CommandNotFoundException] {
        # 'Get-DnsServerZone' 명령어를 찾을 수 없는 경우 (DNS 서버 역할이 설치되지 않음)
        Write-Host "[Diagnosis Result: Good ✅]" -ForegroundColor Green
        Write-Host "Reason: DNS server role (feature) is not installed."
    }
    catch {
        Write-Error "An error occurred during the check: $($_.Exception.Message)"
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
Test-W63DNSServiceOperationCheck

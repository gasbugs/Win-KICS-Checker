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
            $details = "DNS 서버 역할이 설치되어 있지 않거나, 설정된 주 영역(Primary Zone)이 없습니다."
            Write-Host "[진단 결과: 양호 ✅]" -ForegroundColor Green
            Write-Host "원인: DNS 서버 역할이 설치되어 있지 않거나, 설정된 주 영역(Primary Zone)이 없습니다."
            Exit
        }

        # 주 영역 중에서 동적 업데이트 설정이 'None'(없음)이 아닌 영역을 찾습니다.
        $vulnerableZones = $primaryZones | Where-Object { $_.DynamicUpdate -ne 'None' }

        # 동적 업데이트가 설정된 영역이 하나라도 있는지 확인
        if ($vulnerableZones) {
            # 하나라도 있으면 '취약'
            $result = "Vulnerable"
            $details = "다음 DNS 영역에서 동적 업데이트가 허용되도록 설정되어 있습니다."
            Write-Host "[진단 결과: 취약 🚨]" -ForegroundColor Red
            Write-Host "원인: 다음 DNS 영역에서 동적 업데이트가 허용되도록 설정되어 있습니다."
            $vulnerableZones | ForEach-Object {
                Write-Host (" - 영역 이름: {0}, 현재 설정: {1}" -f $_.ZoneName, $_.DynamicUpdate)
            }
        } else {
            # 모두 'None'으로 설정되어 있으면 '양호'
            $details = "모든 DNS 주 영역의 동적 업데이트가 '없음(None)'으로 올바르게 설정되어 있습니다."
            Write-Host "[진단 결과: 양호 ✅]" -ForegroundColor Green
            Write-Host "모든 DNS 주 영역의 동적 업데이트가 '없음(None)'으로 올바르게 설정되어 있습니다."
        }

    }
    catch [System.Management.Automation.CommandNotFoundException] {
        # 'Get-DnsServerZone' 명령어를 찾을 수 없는 경우 (DNS 서버 역할이 설치되지 않음)
        Write-Host "[진단 결과: 양호 ✅]" -ForegroundColor Green
        Write-Host "원인: DNS 서버 역할(기능)이 설치되어 있지 않습니다."
    }
    catch {
        Write-Error "점검 중 오류가 발생했습니다: $($_.Exception.Message)"
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

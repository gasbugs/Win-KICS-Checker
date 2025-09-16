<#
.SYNOPSIS
    Checks event log settings based on a custom policy where 'Circular' mode is considered compliant.

.DESCRIPTION
    This script is modified for environments that use an external logging server (SIEM).
    It verifies that logs are set to 'Circular' (Overwrite events as needed) to prevent local log files
    from filling up, assuming logs are securely forwarded externally.

.OUTPUTS
    A JSON object reflecting the custom operational requirement.
#>
function Test-W70EventLogManagementSettings_Custom {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-70"
    $category = "Log Management"
    $result = "Good"
    $vulnerableDetails = [System.Collections.Generic.List[string]]::new()

    # --- 권장 기준 ---
    $minRecommendedSizeKB = 10240

    # 시스템의 모든 '활성화된' 로그 이름 가져오기   
    $logNames = Get-WinEvent -ListLog * | Where-Object { $_.IsEnabled } | Select-Object -ExpandProperty LogName

    try {
        
        if ($logNames.Count -eq 0) {
            $result = "Error"
            $details = "No enabled event logs found on the system. On the remote target computer, run lusrmgr.msc, then add the account used for the remote connection to the Event Log Readers group."
            $output = @{
                CheckItem = $checkItem
                Category  = $category
                Result    = $result
                Details   = $details
                Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
            return $output | ConvertTo-Json -Depth 4
        }

        foreach ($logName in $logNames) {
            try {
                $logConfig = Get-WinEvent -ListLog $logName -ErrorAction Stop
                
                $currentSizeKB = $logConfig.MaximumSizeInBytes / 1KB
                $isSizeVulnerable = $currentSizeKB -lt $minRecommendedSizeKB
                
                # =====================[ 수정된 부분 ]=====================
                # 사용자의 운영 기준에 따라 'Circular'를 '양호'로 판단하는 로직
                $isRetentionVulnerable = $false
                $retentionDetail = ""

                switch ($logConfig.LogMode) {
                    "Circular" {
                        # '덮어쓰기'가 이 환경의 목표 설정이므로 '양호'로 처리
                        $isRetentionVulnerable = $false
                        $retentionDetail = "Mode: Circular (Compliant as per requirement)"
                    }
                    "Retain" {
                        # 목표 설정(Circular)과 다르므로 '취약'으로 처리
                        $isRetentionVulnerable = $true
                        $retentionDetail = "Mode: Retain (Non-compliant, expected 'Circular')"
                    }
                    "OverwriteOlder" {
                        # 목표 설정(Circular)과 다르므로 '취약'으로 처리
                        $isRetentionVulnerable = $true
                        $retentionDetail = "Mode: OverwriteOlder (Non-compliant, expected 'Circular')"
                    }
                }
                # =========================================================

                if ($isSizeVulnerable -or $isRetentionVulnerable) {
                    $result = "Vulnerable"
                    $detail = "▶ [$($logName)] Vulnerable. Size: $currentSizeKB KB. $retentionDetail"
                    if ($isSizeVulnerable) { $detail += " (Size requirement not met)" }
                    $vulnerableDetails.Add($detail)
                }

            } catch { /* 개별 로그 오류는 건너뜁니다 */ }
        }

        if ($result -eq "Good") {
            $details = "All checked logs meet the custom criteria (Size >= 10240KB, Mode = Circular)."
        } else {
            $details = "Some logs do not meet the custom criteria.`n" + ($vulnerableDetails -join "`n")
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category  = $category
        Result    = $result
        Details   = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $output | ConvertTo-Json -Depth 4
}

# 함수 실행
Test-W70EventLogManagementSettings_Custom
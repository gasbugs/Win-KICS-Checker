<#
.SYNOPSIS
    Checks KISA security item W-81: Analyze Startup Program List.

.DESCRIPTION
    This script gathers a comprehensive list of items that are configured to run automatically at startup or logon.
    Since determining whether a program is 'unnecessary' requires manual review, the script's result is always
    'Manual Check Required'. It provides the collected list for an administrator to inspect.

.OUTPUTS
    A JSON object with the result set to 'Manual Check Required' and a detailed list of startup items.
#>
function Test-W81_AnalyzeStartupPrograms {
    [CmdletBinding()]
    param()
    
    # --- 점검 기본 정보 ---
    $checkItem = "W-81"
    $category = "Security Management"
    $result = "Manual Check Required"
    $startupItems = [System.Collections.Generic.List[object]]::new()

    try {
        # =====================[ 수정된 부분 시작 ]=====================
        # --- 1. 레지스트리 Run 키 점검 (더 안정적인 방식으로 변경) ---
        $regPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
        )
        foreach ($path in $regPaths) {
            if (Test-Path $path) {
                # Get-Item으로 키 객체를 직접 가져옵니다.
                $key = Get-Item -Path $path
                
                # 키에 포함된 모든 값의 이름을 가져와서 반복 처리합니다.
                # 이 방식은 키가 비어있어도 오류가 발생하지 않으며, PowerShell 관리 속성을 가져오지 않습니다.
                foreach ($valueName in $key.GetValueNames()) {
                    # 이름이 없는 '(기본값)'은 제외합니다.
                    if ($valueName) {
                        $startupItems.Add([PSCustomObject]@{
                            Type     = "Registry Run Key"
                            Location = $path
                            Name     = $valueName
                            Command  = $key.GetValue($valueName)
                        })
                    }
                }
            }
        }
        # =====================[ 수정된 부분 끝 ]=====================

        # --- 2. 시작 프로그램 폴더 점검 (기존과 동일) ---
        $startupFolders = @(
            [System.Environment]::GetFolderPath('Startup'),
            [System.Environment]::GetFolderPath('CommonStartup')
        )
        foreach ($folder in $startupFolders) {
            if (Test-Path $folder) {
                Get-ChildItem -Path $folder | ForEach-Object {
                    $startupItems.Add([PSCustomObject]@{
                        Type      = "Startup Folder"
                        Location  = $folder
                        Name      = $_.Name
                        Command   = $_.FullName
                    })
                }
            }
        }

        # --- 3. 자동 시작 서비스 점검 (기존과 동일) ---
        Get-Service | Where-Object { $_.StartType -eq 'Automatic' } | ForEach-Object {
            $startupItems.Add([PSCustomObject]@{
                Type      = "Service"
                Location  = "Services (services.msc)"
                Name      = $_.Name
                Command   = $_.DisplayName
            })
        }
        
        $details = "A list of all startup programs and services has been collected for manual review. Please check for any unnecessary items."

    }
    catch {
        $result = "Error"
        $details = "An error occurred while gathering startup items: $($_.Exception.Message)"
    }

    # --- 결과를 JSON 형식으로 출력 ---
    $output = @{
        CheckItem    = $checkItem
        Category     = $category
        Result       = $result
        Details      = $details
        StartupItems = $startupItems
        Timestamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    $output | ConvertTo-Json -Depth 4
}

# 함수 실행
Test-W81_AnalyzeStartupPrograms
<#
.SYNOPSIS
    Checks KISA security item W-71 by inspecting multiple critical log directories for 'Everyone' group permissions.

.DESCRIPTION
    This script inspects the ACLs of primary system and IIS log directories.
    It flags the system as 'Vulnerable' if any permission entry for the 'Everyone' group exists
    on any of the specified directories.

.OUTPUTS
    A JSON object with the consolidated check result (Good or Vulnerable) and details.
#>
function Test-W71_MultiDirectoryPermissions {
    [CmdletBinding()]
    param()
    
    # --- 점검 기본 정보 ---
    $checkItem = "W-71"
    $category = "Log Management"
    $result = "Good" # 기본 상태를 '양호'로 설정
    $vulnerableFindings = [System.Collections.Generic.List[string]]::new()

    try {
        # --- 점검할 디렉터리 목록 ---
        # %SystemRoot%는 C:\Windows 또는 C:\winnt 와 같은 시스템 폴더를 의미합니다.
        $logDirectoryPaths = @(
            (Join-Path -Path $env:SystemRoot -ChildPath "System32\config"),
            (Join-Path -Path $env:SystemRoot -ChildPath "System32\LogFiles")
        )

        # --- 각 디렉터리에 대해 반복 점검 ---
        foreach ($path in $logDirectoryPaths) {
            if (-not (Test-Path $path)) {
                # 점검 대상 경로가 없으면 건너뜁니다. (예: IIS가 설치되지 않은 경우)
                continue
            }

            # 디렉터리 접근 제어 목록(ACL) 가져오기
            $acl = Get-Acl -Path $path

            # ACL 항목 중 'Everyone' 그룹이 있는지 확인
            $everyoneAce = $acl.Access | Where-Object { $_.IdentityReference.Value -like "Everyone" }

            if ($null -ne $everyoneAce) {
                # 'Everyone' 그룹 권한이 하나라도 발견되면 전체 결과를 '취약'으로 설정
                $result = "Vulnerable"
                $permissions = $everyoneAce.FileSystemRights.ToString()
                # 어떤 디렉터리에서 취약점이 발견되었는지 상세히 기록
                $vulnerableFindings.Add("In directory '$($path)': The 'Everyone' group was found with the right(s): '$($permissions)'.")
            }
        }

        # --- 최종 결과 정리 ---
        if ($result -eq "Vulnerable") {
            $details = "Vulnerability found. Excessive permissions for the 'Everyone' group exist on one or more log directories.`n" + ($vulnerableFindings -join "`n")
        } else {
            $details = "Checked directories are compliant. No permissions for the 'Everyone' group were found.`nChecked paths: $($logDirectoryPaths -join ', ')"
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking permissions: $($_.Exception.Message)"
    }

    # --- 결과를 JSON 형식으로 출력 ---
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
Test-W71_MultiDirectoryPermissions
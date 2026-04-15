# W-62: 시작프로그램 목록 분석
function Test-W62 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem     = "W-62"
        Category      = "보안 관리"
        Result        = "Manual Check Required"
        Details       = ""
        StartupItems  = @()
        Timestamp     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        # 레지스트리 Run 키
        $runKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
        )

        foreach ($key in $runKeys) {
            if (Test-Path $key) {
                $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
                $props.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
                    $result.StartupItems += @{
                        Source = $key
                        Name   = $_.Name
                        Value  = $_.Value
                    }
                }
            }
        }

        # 시작 폴더
        $startupFolders = @(
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
        )

        foreach ($folder in $startupFolders) {
            if (Test-Path $folder) {
                Get-ChildItem -Path $folder -ErrorAction SilentlyContinue | ForEach-Object {
                    $result.StartupItems += @{
                        Source = $folder
                        Name   = $_.Name
                        Value  = $_.FullName
                    }
                }
            }
        }

        $result.Details = "Found $($result.StartupItems.Count) startup item(s). Review for suspicious entries."
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while analyzing startup programs: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W62

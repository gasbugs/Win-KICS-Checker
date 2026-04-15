# W-35: 불필요한 ODBC/OLE-DB 데이터 소스와 드라이브 제거
function Test-W35 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem   = "W-35"
        Category    = "서비스 관리"
        Result      = "Good"
        Details     = ""
        SystemDSNs  = @()
        Timestamp   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $regPath = "HKLM:\SOFTWARE\ODBC\ODBC.INI"
        if (-not (Test-Path $regPath)) {
            $result.Details = "No ODBC DSNs configured."
            $result | ConvertTo-Json -Depth 4
            return
        }

        $dsnNames = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -ne 'ODBC Data Sources' }

        if ($dsnNames.Count -eq 0) {
            $result.Details = "No System DSNs found."
            $result | ConvertTo-Json -Depth 4
            return
        }

        foreach ($dsn in $dsnNames) {
            $props = Get-ItemProperty -Path $dsn.PSPath -ErrorAction SilentlyContinue
            $result.SystemDSNs += @{
                Name        = $dsn.PSChildName
                Driver      = $props.Driver
                Description = $props.Description
                Server      = $props.Server
            }
        }

        $result.Result  = "Manual Check Required"
        $result.Details = "Found $($dsnNames.Count) System DSN(s). Review if they are necessary."
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking ODBC DSNs: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W35

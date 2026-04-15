# W-27: 최신 Windows OS Build 버전 적용
function Test-W27 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-27"
        Category  = "서비스 관리"
        Result    = "Manual Check Required"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem
        $version   = $os.Version
        $buildNum  = $os.BuildNumber
        $caption   = $os.Caption
        $spVersion = $os.ServicePackMajorVersion

        $result.Details = "OS: $caption, Version: $version, Build: $buildNum, SP: $spVersion. Verify that this is the latest available build."
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking OS version: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W27

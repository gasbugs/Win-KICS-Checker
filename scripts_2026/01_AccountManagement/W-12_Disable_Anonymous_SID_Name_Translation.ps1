# W-12: 익명 SID/이름 변환 허용 해제
function Test-W12 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-12"
        Category  = "계정 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $value = ($content | Select-String -Pattern "LSAAnonymousNameLookup" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        if ($value -eq 0) {
            $result.Details = "The 'Allow anonymous SID/name translation' policy is disabled."
        } else {
            $result.Result  = "Vulnerable"
            $result.Details = "The 'Allow anonymous SID/name translation' policy is enabled (Current value: $value)."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W12

# W-05: 해독 가능한 암호화를 사용하여 암호 저장 해제
function Test-W05 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-05"
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

        $policyLine = $content | Select-String -Pattern "ClearTextPassword"

        if ($policyLine) {
            $value = $policyLine.ToString().Split('=')[1].Trim()
            if ($value -eq "0") {
                $result.Details = "Storing passwords using reversible encryption is disabled (Value: 0)."
            } else {
                $result.Result  = "Vulnerable"
                $result.Details = "Storing passwords using reversible encryption is enabled (Value: $value)."
            }
        } else {
            $result.Details = "Storing passwords using reversible encryption is not configured, which defaults to disabled."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking the reversible encryption policy: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W05

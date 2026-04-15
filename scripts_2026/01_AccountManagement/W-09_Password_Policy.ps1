# W-09: 비밀번호 관리정책 설정
# 2026 통합 항목: 복잡성, 최소길이, 최대사용기간, 최소사용기간, 암호기억
function Test-W09 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem     = "W-09"
        Category      = "계정 관리"
        Result        = "Good"
        Details       = ""
        PolicyDetails = @{}
        Timestamp     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        # 정책 값 추출
        $complexity    = ($content | Select-String -Pattern "PasswordComplexity" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $minLength     = ($content | Select-String -Pattern "MinimumPasswordLength" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $maxAge        = ($content | Select-String -Pattern "MaximumPasswordAge" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $minAge        = ($content | Select-String -Pattern "MinimumPasswordAge" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $historySize   = ($content | Select-String -Pattern "PasswordHistorySize" |
            ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        $result.PolicyDetails = @{
            PasswordComplexity   = $complexity
            MinimumPasswordLength = $minLength
            MaximumPasswordAge   = $maxAge
            MinimumPasswordAge   = $minAge
            PasswordHistorySize  = $historySize
        }

        $vulnerabilities = @()

        # 복잡성 점검: 1이어야 함
        if ($complexity -ne 1) {
            $vulnerabilities += "Password complexity is disabled (Value: $complexity, Required: 1)"
        }

        # 최소 길이 점검: 8자 이상
        if ($minLength -lt 8) {
            $vulnerabilities += "Minimum password length is $minLength (Required: >= 8)"
        }

        # 최대 사용 기간 점검: 90일 이하, 0(무제한)은 취약
        if ($maxAge -eq 0) {
            $vulnerabilities += "Maximum password age is set to never expire"
        } elseif ($maxAge -gt 90) {
            $vulnerabilities += "Maximum password age is $maxAge days (Required: <= 90)"
        }

        # 최소 사용 기간 점검: 1일 이상
        if ($minAge -lt 1) {
            $vulnerabilities += "Minimum password age is $minAge days (Required: >= 1)"
        }

        # 암호 기억 점검: 4개 이상
        if ($historySize -lt 4) {
            $vulnerabilities += "Password history size is $historySize (Required: >= 4)"
        }

        if ($vulnerabilities.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Password policy issues found: " + ($vulnerabilities -join "; ")
        } else {
            $result.Details = "All password policies meet recommended standards. Complexity: Enabled, MinLength: $minLength, MaxAge: ${maxAge}d, MinAge: ${minAge}d, History: $historySize."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking password policies: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W09

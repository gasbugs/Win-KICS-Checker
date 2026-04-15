# W-46: SAM 파일 접근 통제 설정
function Test-W46 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-46"
        Category  = "보안 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $samPath = "$env:SystemRoot\System32\config\SAM"

        if (-not (Test-Path $samPath)) {
            $result.Result  = "Error"
            $result.Details = "SAM file not found at $samPath."
            $result | ConvertTo-Json -Depth 4
            return
        }

        $acl = Get-Acl $samPath -ErrorAction Stop
        $allowedSIDs = @("S-1-5-32-544", "S-1-5-18")  # Administrators, SYSTEM
        $issues = @()

        foreach ($ace in $acl.Access) {
            $sid = $ace.IdentityReference
            try {
                $sid = (New-Object System.Security.Principal.NTAccount($ace.IdentityReference)).Translate([System.Security.Principal.SecurityIdentifier]).Value
            } catch {}

            if ($sid -notin $allowedSIDs -and $ace.FileSystemRights -match 'Write|Modify|FullControl') {
                $issues += "$($ace.IdentityReference) has $($ace.FileSystemRights)"
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "SAM file has excessive permissions: $($issues -join '; ')"
        } else {
            $result.Details = "SAM file access control is properly configured."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking SAM file permissions: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W46

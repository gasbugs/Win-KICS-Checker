<#
.SYNOPSIS
    Checks if the 'Network security: LAN Manager authentication level' policy is set to 'Send NTLMv2 response only'.

.DESCRIPTION
    This script verifies the LAN Manager authentication level, which determines the challenge/response authentication protocol used for network logons.
    Setting it to 'Send NTLMv2 response only' (level 4 or 5) enhances security by preventing the use of weaker LM and NTLM protocols.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W77LANManagerAuthenticationLevel {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-77"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $lmAuthenticationLevel = ($content | Select-String -Pattern "LMAUTHENTICATIONLEVEL" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        # Good: 4 (Send NTLMv2 response only) or 5 (Send NTLMv2 response only. Refuse LM & NTLM)
        if ($lmAuthenticationLevel -ge 4) {
            $details = "The 'Network security: LAN Manager authentication level' policy is set to $lmAuthenticationLevel (Send NTLMv2 response only)."
        } else {
            $result = "Vulnerable"
            $details = "The 'Network security: LAN Manager authentication level' policy is set to $lmAuthenticationLevel, which is weaker than recommended (Should be 4 or 5)."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking LAN Manager authentication level: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W77LANManagerAuthenticationLevel

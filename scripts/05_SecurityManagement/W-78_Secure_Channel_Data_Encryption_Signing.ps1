<#
.SYNOPSIS
    Checks if secure channel data digital encryption or signing policies are enabled.

.DESCRIPTION
    This script verifies three security policies related to secure channel data protection.
    These policies ensure that secure channel data is digitally encrypted or signed,
    protecting against various network attacks.
    It uses 'secedit /export' to retrieve the local security policy settings.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W78SecureChannelDataEncryptionSigning {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-78"
    $category = "Security Management"
    $result = "Good"
    $details = @()

    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        secedit /export /cfg $tempFile /areas SECURITYPOLICY /quiet
        $content = Get-Content $tempFile
        Remove-Item $tempFile

        $requireSignOrSeal = ($content | Select-String -Pattern "RequireSignOrSeal" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $sealSecureChannel = ($content | Select-String -Pattern "SealSecureChannel" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]
        $signSecureChannel = ($content | Select-String -Pattern "SignSecureChannel" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }) -as [int]

        $isRequireSignOrSealGood = ($requireSignOrSeal -eq 1)
        $isSealSecureChannelGood = ($sealSecureChannel -eq 1)
        $isSignSecureChannelGood = ($signSecureChannel -eq 1)

        if ($isRequireSignOrSealGood -and $isSealSecureChannelGood -and $isSignSecureChannelGood) {
            $details = "All three secure channel data encryption/signing policies are enabled."
        } else {
            $result = "Vulnerable"
            if (-not $isRequireSignOrSealGood) {
                $details += "'Domain member: Digitally encrypt or sign secure channel data (always)' policy is not enabled (Current: $requireSignOrSeal). "
            }
            if (-not $isSealSecureChannelGood) {
                $details += "'Domain member: Digitally encrypt secure channel data (when possible)' policy is not enabled (Current: $sealSecureChannel). "
            }
            if (-not $isSignSecureChannelGood) {
                $details += "'Domain member: Digitally sign secure channel data (when possible)' policy is not enabled (Current: $signSecureChannel). "
            }
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking secure channel data encryption/signing policies: $($_.Exception.Message)"
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
Test-W78SecureChannelDataEncryptionSigning

<#
.SYNOPSIS
    Checks if the 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' and 'Network access: Do not allow anonymous enumeration of SAM accounts' policies are enabled.

.DESCRIPTION
    This script verifies if the security policies that prevent anonymous enumeration of SAM accounts and shares are enabled.
    These policies are controlled by the 'RestrictAnonymous' and 'RestrictAnonymousSAM' registry values under HKLM:\SYSTEM\CurrentControlSet\Control\Lsa.
    A value of 1 for both indicates the policies are enabled (Good), preventing information disclosure.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W42DisableAnonymousSAMEnumeration {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-42"
    $category = "Security Management"
    $result = "Good"
    $details = @()

    try {
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $restrictAnonymousProperty = "RestrictAnonymous"
        $restrictAnonymousSAMProperty = "RestrictAnonymousSAM"
        
        if (Test-Path $registryPath) {
            $restrictAnonymousValue = (Get-ItemProperty -Path $registryPath -Name $restrictAnonymousProperty -ErrorAction SilentlyContinue).$restrictAnonymousProperty
            $restrictAnonymousSAMValue = (Get-ItemProperty -Path $registryPath -Name $restrictAnonymousSAMProperty -ErrorAction SilentlyContinue).$restrictAnonymousSAMProperty

            # Default to 0 if not found, as per policy interpretation
            if ($null -eq $restrictAnonymousValue) { $restrictAnonymousValue = 0 }
            if ($null -eq $restrictAnonymousSAMValue) { $restrictAnonymousSAMValue = 0 }

            $isRestrictAnonymousGood = ($restrictAnonymousValue -eq 1)
            $isRestrictAnonymousSAMGood = ($restrictAnonymousSAMValue -eq 1)

            if ($isRestrictAnonymousGood -and $isRestrictAnonymousSAMGood) {
                $details = "Both 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' (RestrictAnonymous: 1) and 'Network access: Do not allow anonymous enumeration of SAM accounts' (RestrictAnonymousSAM: 1) policies are enabled."
            } else {
                $result = "Vulnerable"
                if (-not $isRestrictAnonymousGood) {
                    $details += "'Network access: Do not allow anonymous enumeration of SAM accounts and shares' policy is disabled (RestrictAnonymous: $restrictAnonymousValue). "
                }
                if (-not $isRestrictAnonymousSAMGood) {
                    $details += "'Network access: Do not allow anonymous enumeration of SAM accounts' policy is disabled (RestrictAnonymousSAM: $restrictAnonymousSAMValue). "
                }
            }
        } else {
            $result = "Error"
            $details = "Registry path '$registryPath' not found. Cannot verify SAM enumeration policies."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking SAM enumeration policies: $($_.Exception.Message)"
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
Test-W42DisableAnonymousSAMEnumeration

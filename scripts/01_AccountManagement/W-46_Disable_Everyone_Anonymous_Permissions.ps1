<#
.SYNOPSIS
    Checks if the 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' policy is enabled.

.DESCRIPTION
    This script verifies the status of the security policy 'Network access: Do not allow anonymous enumeration of SAM accounts and shares'.
    This policy is typically controlled by the 'RestrictAnonymous' registry value under HKLM:\SYSTEM\CurrentControlSet\Control\Lsa.
    A value of 1 indicates the policy is enabled (Good), meaning anonymous users cannot enumerate SAM accounts and shares.
    A value of 0 or absence of the key indicates the policy is disabled (Vulnerable).

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W46DisableEveryoneAnonymousPermissions {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-46"
    $category = "Account Management"
    $result = "Good"
    $details = ""

    try {
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        # EveryoneIncludesAnonymous: 0=Disabled, 1=Enabled
        $propertyName = "EveryoneIncludesAnonymous"
        
        if (Test-Path $registryPath) {
            $restrictAnonymousValue = (Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue).$propertyName

            if ($null -eq $restrictAnonymousValue -or $restrictAnonymousValue -eq 0) {
                $result = "Vulnerable"
                $details = "The 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' policy is disabled or not configured (RestrictAnonymous value: $($restrictAnonymousValue -replace '^$', 'Not Set')). Anonymous users might be able to enumerate SAM accounts and shares."
            } elseif ($restrictAnonymousValue -eq 1) {
                $details = "The 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' policy is enabled (RestrictAnonymous value: 1)."
            } else {
                $result = "Vulnerable"
                $details = "The 'RestrictAnonymous' registry value has an unexpected value: $restrictAnonymousValue."
            }
        } else {
            $result = "Vulnerable"
            $details = "Registry path '$registryPath' not found. Unable to verify 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' policy."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking the policy: $($_.Exception.Message)"
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
Test-W46DisableEveryoneAnonymousPermissions

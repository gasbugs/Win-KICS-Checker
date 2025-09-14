<#
.SYNOPSIS
    Checks if Autologon is disabled.

.DESCRIPTION
    This script verifies the status of the Autologon feature by checking the 'AutoAdminLogon' registry value.
    If 'AutoAdminLogon' is absent or set to 0, it indicates that Autologon is disabled (Good),
    preventing the exposure of login credentials.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W43AutologonFeatureControl {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-43"
    $category = "Security Management"
    $result = "Good"
    $details = ""

    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $propertyName = "AutoAdminLogon"
        
        if (Test-Path $registryPath) {
            $autoAdminLogonValue = (Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue).$propertyName

            if ($null -eq $autoAdminLogonValue -or $autoAdminLogonValue -eq 0) {
                $details = "Autologon is disabled (AutoAdminLogon value is absent or 0)."
            } elseif ($autoAdminLogonValue -eq 1) {
                $result = "Vulnerable"
                $details = "Autologon is enabled (AutoAdminLogon value is 1)."
            } else {
                $result = "Vulnerable"
                $details = "The 'AutoAdminLogon' registry value has an unexpected value: $autoAdminLogonValue."
            }
        } else {
            $result = "Error"
            $details = "Registry path '$registryPath' not found. Cannot verify Autologon feature."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking Autologon feature: $($_.Exception.Message)"
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
Test-W43AutologonFeatureControl

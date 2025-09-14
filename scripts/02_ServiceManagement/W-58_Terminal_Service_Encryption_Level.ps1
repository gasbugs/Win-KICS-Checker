<#
.SYNOPSIS
    Checks if the Terminal Services encryption level is set to 'Client Compatible (Medium)' or higher.

.DESCRIPTION
    This script verifies the encryption level configured for Terminal Services (RDP).
    A higher encryption level protects data transmitted between the client and server.
    It checks the 'MinEncryptionLevel' registry value.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W58TerminalServiceEncryptionLevel {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-58"
    $category = "Service Management"
    $result = "Good"
    $details = ""
    $minRecommendedLevel = 2 # 2: Client Compatible (Medium), 3: High, 4: FIPS Compliant

    try {
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $propertyName = "MinEncryptionLevel"
        
        if (Test-Path $registryPath) {
            $encryptionLevel = (Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction SilentlyContinue).$propertyName

            if ($null -eq $encryptionLevel) {
                $result = "Vulnerable"
                $details = "'MinEncryptionLevel' registry value not found at '$registryPath'. Default encryption level might be low."
            } elseif ($encryptionLevel -ge $minRecommendedLevel) {
                $details = "Terminal Services encryption level is set to $encryptionLevel (Recommended: >= $minRecommendedLevel)."
            } else {
                $result = "Vulnerable"
                $details = "Terminal Services encryption level is set to $encryptionLevel, which is lower than the recommended $minRecommendedLevel."
            }
        } else {
            $result = "Error"
            $details = "Registry path '$registryPath' not found. Terminal Services might not be installed or configured."
        }
    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking Terminal Services encryption level: $($_.Exception.Message)"
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
Test-W58TerminalServiceEncryptionLevel

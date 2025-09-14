# W-08: Remove Default Hard Disk Shares
# Checks registry settings and the existence of default administrative shares (e.g., C$, D$).

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-08'
    Category = 'Service Management'
    Result = '' # To be determined
    Details = '' # To be determined
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

try {
    # 1. Check for existence of default admin shares (C$, D$, etc.)
    $adminShares = Get-CimInstance -Class Win32_Share | Where-Object { $_.Type -eq 0 -and $_.Name -match '^[A-Z]\$$' }
    $sharesExist = $null -ne $adminShares

    # 2. Check the registry key value
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    $regValue = $null
    $regKeyName = ""

    $autoShareServer = Get-ItemProperty -Path $regPath -Name "AutoShareServer" -ErrorAction SilentlyContinue
    if ($null -ne $autoShareServer) {
        $regValue = $autoShareServer.AutoShareServer
        $regKeyName = "AutoShareServer"
    } else {
        $autoShareWks = Get-ItemProperty -Path $regPath -Name "AutoShareWks" -ErrorAction SilentlyContinue
        if ($null -ne $autoShareWks) {
            $regValue = $autoShareWks.AutoShareWks
            $regKeyName = "AutoShareWks"
        }
    }

    # If key doesn't exist, the default is 1 (enabled)
    $regValueForLogic = if ($null -eq $regValue) { 1 } else { $regValue }
    if ($null -eq $regValue) { $regKeyName = "Not Set" }

    # 3. Apply the logic from the guide
    # Vulnerable: regValue is 1 OR shares exist
    if ($regValueForLogic -eq 1 -or $sharesExist) {
        $result.Result = 'Vulnerable'
        $detailsParts = @()
        if ($sharesExist) {
            $shareNames = ($adminShares | ForEach-Object { $_.Name }) -join ', '
            $detailsParts += "Default administrative shares are present: $shareNames."
        }
        if ($regValueForLogic -eq 1) {
            if ($regKeyName -eq "Not Set") {
                $detailsParts += "The registry key for auto-sharing is not set, which defaults to enabled."
            } else {
                $detailsParts += "The registry key '$regKeyName' is set to 1 (enabled)."
            }
        }
        $result.Details = $detailsParts -join ' '
    } else {
        # Good: regValue is 0 AND shares do not exist
        $result.Result = 'Good'
        $result.Details = "No default administrative drive shares found and the registry key '$regKeyName' is correctly set to 0."
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking for default shares: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Compress

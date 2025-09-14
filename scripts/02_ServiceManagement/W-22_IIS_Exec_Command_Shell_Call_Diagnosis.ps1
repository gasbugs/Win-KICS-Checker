# W-22_IIS_Exec_Command_Shell_Call_Diagnosis.ps1
# Checks if IIS Exec command shell calls are enabled.

function Test-IISExecCommandShellCallDiagnosis {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-22"
        Category = "Service Management"
        Result = "Good" # Default to Good
        Details = ""
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    # Get OS Version
    $osVersion = [System.Environment]::OSVersion.Version

    # IIS 6.0+ (Windows 2003 and later) is always Good (not applicable)
    if ($osVersion.Major -gt 5 -or ($osVersion.Major -eq 5 -and $osVersion.Minor -ge 2)) { # Covers Windows 2003 (5.2) and newer
        $result.Details = "This check is not applicable for IIS 6.0 and later versions. Current OS version is $($osVersion.Major).$($osVersion.Minor)."
        return $result
    }

    # For IIS 5.0 (Windows 2000)
    # Check HKLM\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\SSIEnableCmdDirective
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters"
    $propertyName = "SSIEnableCmdDirective"

    try {
        $ssiEnableCmdDirective = Get-ItemProperty -Path $registryPath -Name $propertyName -ErrorAction Stop | Select-Object -ExpandProperty $propertyName
        if ($ssiEnableCmdDirective -eq 0) {
            $result.Result = "Good"
            $result.Details = "SSIEnableCmdDirective is set to 0 (disabled)."
        } elseif ($ssiEnableCmdDirective -eq 1) {
            $result.Result = "Vulnerable"
            $result.Details = "SSIEnableCmdDirective is set to 1 (enabled), allowing IIS Exec command shell calls."
        } else {
            $result.Result = "Manual Check Required"
            $result.Details = "SSIEnableCmdDirective has an unexpected value: $($ssiEnableCmdDirective). Manual check required."
        }
    } catch {
        $result.Result = "Good" # If registry key/value not found, it's considered good (default disabled)
        $result.Details = "SSIEnableCmdDirective registry key/value not found or inaccessible. Assuming disabled. Error: $($_.Exception.Message)"
    }

    return $result
}

Test-IISExecCommandShellCallDiagnosis | ConvertTo-Json -Depth 100
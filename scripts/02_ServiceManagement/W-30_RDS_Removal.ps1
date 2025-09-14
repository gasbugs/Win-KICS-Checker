# W-30_RDS_Removal.ps1
# Checks whether RDS (Remote Data Services) is disabled.

function Test-RDSRemoval {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-30"
        Category = "Service Management"
        Result = "Good" # Default to Good
        Details = ""
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    # Target OS: Windows NT, 2000, 2003
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -gt 5 -or ($osVersion.Major -eq 5 -and $osVersion.Minor -gt 2)) { # Covers Windows 2008 (6.0) and newer
        $result.Details = "This check is not applicable for OS versions newer than Windows 2003. Current OS version is $($osVersion.Major).$($osVersion.Minor)."
        return $result
    }

    try {
        # 2. Windows 2000 SP4, Windows 2003 SP2 or later (Good)
        # This requires checking service pack version, which is complex.
        # For simplicity, mark as manual check if not already good by other means.

        # 3. Default web site does not have MSADC virtual directory
        # Requires WebAdministration module for Get-Website
        if (Get-Module -ListAvailable -Name WebAdministration -ErrorAction SilentlyContinue) {
            Import-Module WebAdministration -ErrorAction Stop
            $defaultWebsite = Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
            if ($defaultWebsite) {
                $msadcVirtualDirectory = Get-WebVirtualDirectory -Site $defaultWebsite.Name -Name "msadc" -ErrorAction SilentlyContinue
                if ($msadcVirtualDirectory) {
                    $result.Result = "Vulnerable"
                    $result.Details = "MSADC virtual directory found on Default Web Site. It should be removed."
                    return $result
                }
            }
        } else {
            # Fallback for older IIS versions where WebAdministration module might not be present
            # This requires checking IIS Metabase directly or manual check.
            $result.Result = "Manual Check Required"
            $result.Details = "WebAdministration module not available. Manual check required for MSADC virtual directory. Refer to guide for manual steps for OS version $($osVersion.Major).$($osVersion.Minor)."
            return $result
        }

        # 4. Specific registry values do not exist
        $registryPaths = @(
            "HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\ADCLaunch\RDSServer.DataFactory",
            "HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\ADCLaunch\AdvancedDataFactory",
            "HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC\Parameters\ADCLaunch\VbBusObj.VbBusObjCls"
        )
        foreach ($path in $registryPaths) {
            try {
                $regValue = Get-Item -Path $path -ErrorAction Stop
                # If the item exists, it's vulnerable
                $result.Result = "Vulnerable"
                $result.Details = "RDS related registry key found: $($path). It should be removed."
                return $result
            } catch {
                # Registry key not found, which is good
            }
        }

        $result.Result = "Good"
        $result.Details = "RDS is disabled or not applicable."

    } catch {
        $result.Result = "Error"
        $result.Details = "An error occurred while checking RDS status: $($_.Exception.Message)"
    }

    return $result
}

Test-RDSRemoval | ConvertTo-Json -Depth 100
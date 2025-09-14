# W-14: Remove Unnecessary IIS Files
# Checks for the presence of IISSamples and IISHelp virtual directories.
# NOTE: This check is explicitly NOT APPLICABLE for IIS 7.0 (Windows 2008) and later versions.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-14'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'This check is not applicable for IIS 7.0 (Windows 2008) and later versions, which is likely the current OS version.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

try {
    # Determine OS version to check applicability
    $osVersion = [System.Environment]::OSVersion.Version
    # Windows Server 2008 (IIS 7.0) has OS version 6.0. So, if OS version is 6.0 or greater, it's not applicable.
    if ($osVersion.Major -ge 6) { # Covers Windows Server 2008 (6.0) and newer
        $result.Details = "This check (W-14) is not applicable for IIS 7.0 (Windows Server 2008) and later versions. Current OS version is $($osVersion.Major).$($osVersion.Minor)."
        # Result remains 'Good'
    } else {
        # This block would only run on very old OS (e.g., Windows Server 2003 or older)
        # For completeness, if IIS is installed, check for the virtual directories.
        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
        } else {
            Import-Module WebAdministration -ErrorAction Stop

            $vulnerableSites = @()
            $websites = Get-WebSite -ErrorAction SilentlyContinue

            if ($null -ne $websites) {
                foreach ($site in $websites) {
                    try {
                        # Check for IISSamples virtual directory
                        $iisSamples = Get-WebVirtualDirectory -Site $site.Name -Name "IISSamples" -ErrorAction SilentlyContinue
                        if ($iisSamples) {
                            $vulnerableSites += "$($site.Name)/IISSamples"
                        }
                        # Check for IISHelp virtual directory
                        $iisHelp = Get-WebVirtualDirectory -Site $site.Name -Name "IISHelp" -ErrorAction SilentlyContinue
                        if ($iisHelp) {
                            $vulnerableSites += "$($site.Name)/IISHelp"
                        }
                    } catch {
                        # Write-Warning "Could not check virtual directories for site $($site.Name): $($_.Exception.Message)"
                    }
                }
            }

            if ($vulnerableSites.Count -gt 0) {
                $result.Result = 'Vulnerable'
                $result.Details = "Unnecessary IIS virtual directories found: $($vulnerableSites -join ', '). These should be removed."
            } else {
                $result.Details = "No unnecessary IIS virtual directories (IISSamples, IISHelp) found."
            }
        }
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking for unnecessary IIS files: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Compress

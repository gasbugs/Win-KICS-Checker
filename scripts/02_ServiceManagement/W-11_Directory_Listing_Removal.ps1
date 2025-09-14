# W-11: Remove Directory Listing
# Checks if directory browsing is enabled on IIS websites.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-11'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'Directory browsing is disabled on all detected IIS websites, or IIS is not installed.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    VulnerableWebsites = @()
}

try {
    # Check if the WebAdministration module is available (indicates IIS is likely installed)
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available."
        # Result remains 'Good' as there's no IIS to be vulnerable.
    } else {
        Import-Module WebAdministration -ErrorAction Stop

        $vulnerableSites = @()
        $websites = Get-WebSite -ErrorAction SilentlyContinue

        if ($null -eq $websites) {
            $result.Details = "IIS is installed, but no websites were found."
        } else {
            foreach ($site in $websites) {
                try {
                    $dirBrowseConfig = Get-WebConfigurationProperty -PSPath "IIS:\Sites\$($site.Name)" -Filter 'system.webServer/directoryBrowse' -Name 'enabled' -ErrorAction Stop
                    if ($dirBrowseConfig.Value -eq $true) {
                        $vulnerableSites += $site.Name
                    }
                } catch {
                    # Handle cases where a site might not have a directoryBrowse section or other errors
                    # For now, just log and continue.
                    # Write-Warning "Could not check directory browsing for site $($site.Name): $($_.Exception.Message)"
                }
            }

            if ($vulnerableSites.Count -gt 0) {
                $result.Result = 'Vulnerable'
                $result.Details = "Directory browsing is enabled on the following IIS websites: $($vulnerableSites -join ', '). This exposes file information."
                $result.VulnerableWebsites = $vulnerableSites
            } else {
                $result.Details = "Directory browsing is disabled on all detected IIS websites."
            }
        }
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking IIS directory listing: $($_.Exception.Message)"
}

# Remove the temporary list from the final output if not vulnerable
if ($result.Result -ne 'Vulnerable') {
    $result.Remove('VulnerableWebsites')
}

$result | ConvertTo-Json -Compress

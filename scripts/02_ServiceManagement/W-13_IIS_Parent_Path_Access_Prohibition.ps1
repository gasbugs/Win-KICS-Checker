# W-13: IIS Parent Path Access Restriction
# Checks if "Parent Paths" are disabled in IIS for all websites.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-13'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'Parent path access is disabled on all detected IIS websites, or IIS is not installed.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    VulnerableWebsites = @()
}

try {
    # Check if the WebAdministration module is available (indicates IIS is likely installed)
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
        # Result remains 'Good'
    } else {
        Import-Module WebAdministration -ErrorAction Stop

        $vulnerableSites = @()
        $websites = Get-WebSite -ErrorAction SilentlyContinue

        if ($null -eq $websites) {
            $result.Details = "IIS is installed, but no websites were found."
        } else {
            foreach ($site in $websites) {
                try {
                    # Get the ASP configuration for the site
                    $aspConfig = Get-WebConfigurationProperty -PSPath "IIS:\Sites\$($site.Name)" -Filter 'system.webServer/asp' -Name '*' -ErrorAction SilentlyContinue

                    # Check the EnableParentPaths property
                    if ($aspConfig -and $aspConfig.EnableParentPaths -eq $true) {
                        $vulnerableSites += $site.Name
                    }
                } catch {
                    # Handle cases where a site might not have ASP configured or other errors
                    # Write-Warning "Could not check parent paths for site $($site.Name): $($_.Exception.Message)"
                }
            }

            if ($vulnerableSites.Count -gt 0) {
                $result.Result = 'Vulnerable'
                $result.Details = "Parent path access is enabled on the following IIS websites: $($vulnerableSites -join ', '). This allows access to higher-level directories."
                $result.VulnerableWebsites = $vulnerableSites
            } else {
                $result.Details = "Parent path access is disabled on all detected IIS websites."
            }
        }
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking IIS parent path access: $($_.Exception.Message)"
}

# Remove the temporary list from the final output if not vulnerable
if ($result.Result -ne 'Vulnerable') {
    $result.Remove('VulnerableWebsites')
}

$result | ConvertTo-Json -Compress

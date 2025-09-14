# W-19: Delete Unnecessary IIS Virtual Directories
# Checks for the presence of IIS Admin and IIS Adminpwd virtual directories.
# NOTE: This check is explicitly NOT APPLICABLE for Windows 2003 (IIS 6.0) and later versions.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-19'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'This check is not applicable for Windows 2003 (IIS 6.0) and later versions, which is likely the current OS version.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

try {
    # Determine OS version to check applicability
    $osVersion = [System.Environment]::OSVersion.Version
    # Windows 2003 (IIS 6.0) is OS version 5.2.
    # So, if OS version is 5.2 or greater, it's not applicable.
    if ($osVersion.Major -gt 5 -or ($osVersion.Major -eq 5 -and $osVersion.Minor -ge 2)) { # Covers Windows 2003 (5.2) and newer
        $result.Details = "This check (W-19) is not applicable for Windows 2003 (IIS 6.0) and later versions. Current OS version is $($osVersion.Major).$($osVersion.Minor)."
        # Result remains 'Good'
    } else {
        # This block would only run on very old OS (e.g., Windows 2000 or NT)
        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
        } else {
            Import-Module WebAdministration -ErrorAction Stop

            $vulnerableSites = @()
            $websites = Get-WebSite -ErrorAction SilentlyContinue

            if ($null -ne $websites) {
                foreach ($site in $websites) {
                    try {
                        # Check for IIS Admin virtual directory
                        $iisAdmin = Get-WebVirtualDirectory -Site $site.Name -Name "IISAdmin" -ErrorAction SilentlyContinue
                        if ($iisAdmin) {
                            $vulnerableSites += "$($site.Name)/IISAdmin"
                        }
                        # Check for IISAdminpwd virtual directory
                        $iisAdminpwd = Get-WebVirtualDirectory -Site $site.Name -Name "IISAdminpwd" -ErrorAction SilentlyContinue
                        if ($iisAdminpwd) {
                            $vulnerableSites += "$($site.Name)/IISAdminpwd"
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
                $result.Details = "No unnecessary IIS virtual directories (IISAdmin, IISAdminpwd) found."
            }
        }
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking for unnecessary IIS virtual directories: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Compress

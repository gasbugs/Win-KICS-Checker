# W-16: IIS Link Prohibition
# Checks for the presence of symbolic links, junctions, or .lnk files within IIS website physical paths.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-16'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'No prohibited links or shortcuts found in IIS website directories, or IIS is not installed.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    FoundProhibitedLinks = @()
}

try {
    # Check if the WebAdministration module is available (indicates IIS is likely installed)
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
        # Result remains 'Good'
    } else {
        Import-Module WebAdministration -ErrorAction Stop

        $prohibitedLinks = @()
        $websites = Get-WebSite -ErrorAction SilentlyContinue

        if ($null -eq $websites) {
            $result.Details = "IIS is installed, but no websites were found."
        } else {
            foreach ($site in $websites) {
                try {
                    $physicalPath = $site.physicalPath
                    if (Test-Path $physicalPath -PathType Container) {
                        # Search for symbolic links, junctions, and .lnk files
                        $links = Get-ChildItem -Path $physicalPath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                            $_.LinkType -eq "SymbolicLink" -or $_.LinkType -eq "Junction" -or $_.Extension -eq ".lnk"
                        }

                        if ($links.Count -gt 0) {
                            foreach ($link in $links) {
                                $prohibitedLinks += "$($site.Name): $($link.FullName) (Type: $($link.LinkType -replace 'SymbolicLink', 'Symlink' -replace 'Junction', 'Junction' -replace '.lnk', 'Shortcut'))"
                            }
                        }
                    }
                } catch {
                    # Write-Warning "Could not check links for site $($site.Name): $($_.Exception.Message)"
                }
            }

            if ($prohibitedLinks.Count -gt 0) {
                $result.Result = 'Vulnerable'
                $result.Details = "Prohibited links or shortcuts found in IIS website directories. These can lead to unauthorized access. Found: $($prohibitedLinks -join '; ')."
                $result.FoundProhibitedLinks = $prohibitedLinks
            } else {
                $result.Details = "No prohibited links or shortcuts found in IIS website directories."
            }
        }
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking IIS link prohibition: $($_.Exception.Message)"
}

# Remove the temporary list from the final output if not vulnerable
if ($result.Result -ne 'Vulnerable') {
    $result.Remove('FoundProhibitedLinks')
}

$result | ConvertTo-Json -Compress

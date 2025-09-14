# W-20: Apply ACL to IIS Data Files
# Checks for excessive 'Everyone' permissions on IIS web data files.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-20'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'No excessive Everyone permissions found on IIS data files, or IIS is not installed.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    VulnerableFiles = @()
}

$staticExtensions = @(".txt", ".gif", ".jpg", ".html")
$isVulnerable = $false
$vulnerableFilesList = @()

try {
    # Check if the WebAdministration module is available (indicates IIS is likely installed)
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
        # Result remains 'Good'
    } else {
        Import-Module WebAdministration -ErrorAction Stop

        $websites = Get-WebSite -ErrorAction SilentlyContinue

        if ($null -eq $websites) {
            $result.Details = "IIS is installed, but no websites were found."
        } else {
            foreach ($site in $websites) {
                $physicalPath = $site.physicalPath
                if (Test-Path $physicalPath -PathType Container) {
                    $files = Get-ChildItem -Path $physicalPath -Recurse -File -ErrorAction SilentlyContinue

                    foreach ($file in $files) {
                        try {
                            $acl = Get-Acl $file.FullName
                            $isStaticContent = $staticExtensions -contains $file.Extension.ToLower()

                            foreach ($accessRule in $acl.Access) {
                                if ($accessRule.IdentityReference.Value -eq "Everyone" -or $accessRule.IdentityReference.Value -eq "S-1-1-0") {
                                    # Check for vulnerable permissions
                                    if ($isStaticContent) {
                                        # For static content, only Read is allowed for Everyone
                                        if (-not ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Read) -or
                                            ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write) -or
                                            ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify) -or
                                            ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl)) {
                                            $isVulnerable = $true
                                            $vulnerableFilesList += "$($file.FullName) (Everyone has $($accessRule.FileSystemRights) on static content)"
                                        }
                                    } else {
                                        # For non-static content, no Everyone permission is allowed
                                        $isVulnerable = $true
                                        $vulnerableFilesList += "$($file.FullName) (Everyone has $($accessRule.FileSystemRights) on non-static content)"
                                    }
                                }
                            }
                        } catch {
                            # Write-Warning "Could not check ACL for file $($file.FullName): $($_.Exception.Message)"
                        }
                    }
                }
            }

            if ($isVulnerable) {
                $result.Result = 'Vulnerable'
                $result.Details = "Excessive 'Everyone' permissions found on IIS data files. Found: $($vulnerableFilesList -join '; ')."
                $result.VulnerableFiles = $vulnerableFilesList
            } else {
                $result.Details = "No excessive 'Everyone' permissions found on IIS data files."
            }
        }
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking IIS data file ACLs: $($_.Exception.Message)"
}

# Remove the temporary list from the final output if not vulnerable
if ($result.Result -ne 'Vulnerable') {
    $result.Remove('VulnerableFiles')
}

$result | ConvertTo-Json -Compress

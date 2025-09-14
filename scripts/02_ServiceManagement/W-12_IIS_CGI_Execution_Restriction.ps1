# W-12: IIS CGI Execution Restriction
# Checks if the default CGI directory (C:\inetpub\scripts) grants excessive permissions to 'Everyone'.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-12'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'The default CGI directory does not grant excessive permissions to Everyone, or IIS/directory not found.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

$cgiDirectory = "C:\inetpub\scripts"
$isVulnerable = $false
$vulnerabilityDetails = @()

try {
    # Check if IIS is installed (by checking for WebAdministration module)
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
        # Result remains 'Good'
    } else {
        # Check if the CGI directory exists
        if (-not (Test-Path $cgiDirectory -PathType Container)) {
            $result.Details = "The default CGI directory '$cgiDirectory' does not exist. This check is not applicable."
            # Result remains 'Good'
        } else {
            # Get the ACL for the directory
            $acl = Get-Acl $cgiDirectory

            foreach ($accessRule in $acl.Access) {
                if ($accessRule.IdentityReference.Value -eq "Everyone" -or $accessRule.IdentityReference.Value -eq "S-1-1-0") {
                    # Check for FullControl, Modify, or Write permissions
                    if (($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl) -or
                        ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify) -or
                        ($accessRule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write)) {
                        $isVulnerable = $true
                        $vulnerabilityDetails += "The 'Everyone' group has '$($accessRule.FileSystemRights)' permissions on '$cgiDirectory'."
                    }
                }
            }

            if ($isVulnerable) {
                $result.Result = 'Vulnerable'
                $result.Details = "Excessive permissions granted to 'Everyone' on the default CGI directory. " + ($vulnerabilityDetails -join ' ')
            } else {
                $result.Details = "The default CGI directory '$cgiDirectory' does not grant excessive permissions to 'Everyone'."
            }
        }
    }

} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking IIS CGI execution restrictions: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Compress
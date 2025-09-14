# W-26_FTP_Directory_Access_Permission_Setting.ps1
function Test-FTPDirectoryAccessPermissionSetting {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-26"
        Category = "Service Management"
        Result = "Not Applicable"
        Details = "FTP Service (FTPSVC) not found or not running."
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    $ftpService = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if (-not $ftpService -or $ftpService.Status -ne 'Running') {
        return $result
    }

    $appHostConfigPath = "$env:windir\System32\inetsrv\config\applicationHost.config"
    if (-not (Test-Path $appHostConfigPath)) {
        $result.Result = "Manual Check Required"
        $result.Details = "applicationHost.config not found. FTP configuration could not be verified automatically."
        return $result
    }

    try {
        [xml]$appHostConfig = Get-Content $appHostConfigPath

        $ftpSites = $appHostConfig.configuration.'system.applicationHost'.sites.site | Where-Object { $_.bindings.binding.protocol -eq 'ftp' }

        if (-not $ftpSites) {
            $result.Result = "Good"
            $result.Details = "FTP service is running, but no FTP sites are configured."
            return $result
        }

        $vulnerableSites = @()
        foreach ($site in $ftpSites) {
            $physicalPath = $site.application.virtualDirectory.physicalPath
            try {
                $acl = Get-Acl -Path $physicalPath -ErrorAction Stop
                $everyoneAccess = $acl.Access | Where-Object { $_.IdentityReference.Value -eq 'S-1-1-0' -and ($_.FileSystemRights -band 'Write,Modify,FullControl') }
                if ($everyoneAccess) {
                    $vulnerableSites += $site.name
                }
            } catch {
                Write-Warning "Could not check ACL for path '$($physicalPath)' on site '$($site.name)': $($_.Exception.Message)"
            }
        }

        if ($vulnerableSites.Count -gt 0) {
            $result.Result = "Vulnerable"
            $result.Details = "On the following FTP sites, the home directory grants 'Everyone' dangerous permissions (Write/Modify/FullControl): $($vulnerableSites -join ', ')."
        } else {
            $result.Result = "Good"
            $result.Details = "All checked FTP site home directories have appropriate permissions."
        }
    } catch {
        $result.Result = "Error"
        $result.Details = "Failed to parse applicationHost.config or check permissions: $($_.Exception.Message)"
    }

    return $result
}

Test-FTPDirectoryAccessPermissionSetting | ConvertTo-Json -Depth 100
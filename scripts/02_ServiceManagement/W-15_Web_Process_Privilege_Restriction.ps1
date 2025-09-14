# W-15: Web Process Privilege Restriction
# Checks if IIS web processes are running with minimum necessary privileges (ApplicationPoolIdentity).

function Test-WebProcessPrivilegeRestriction {
    [CmdletBinding()]
    Param()

    $ErrorActionPreference = 'Stop' # Set within the function scope

    $result = @{
        CheckItem = 'W-15'
        Category = 'Service Management'
        Result = 'Good'
        Details = 'IIS web processes are configured with minimum necessary privileges (ApplicationPoolIdentity) or IIS is not installed.'
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        VulnerableAppPools = @()
    }

    try {
        # Check if the WebAdministration module is available and import it
        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            $result.Details = "IIS Web Server is not detected or the WebAdministration PowerShell module is not available. This check is not applicable."
            return $result
        }
        Import-Module WebAdministration -ErrorAction Stop
        if (-not (Get-Module -Name WebAdministration)) {
            $result.Result = 'Manual Check Required'
            $result.Details = "WebAdministration module could not be imported. Manual check required for web process privileges."
            return $result
        }

        # Check if Get-IISAppPool is available
        if (-not (Get-Command -Name Get-IISAppPool -ErrorAction SilentlyContinue)) {
            $result.Result = 'Manual Check Required'
            $result.Details = "Get-IISAppPool cmdlet is not available. Manual check required for web process privileges."
            return $result
        }

        $vulnerablePools = @()
        $appPools = Get-IISAppPool -ErrorAction SilentlyContinue

        if ($null -eq $appPools) {
            $result.Details = "IIS is installed, but no application pools were found."
        } else {
            foreach ($pool in $appPools) {
                # Check if the identityType is not ApplicationPoolIdentity
                # Other types like LocalSystem, NetworkService, SpecificUser (if high priv) are vulnerable
                if ($pool.processModel.identityType -ne "ApplicationPoolIdentity") {
                    $vulnerablePools += "$($pool.Name) (IdentityType: $($pool.processModel.identityType))"
                }
            }

            if ($vulnerablePools.Count -gt 0) {
                $result.Result = 'Vulnerable'
                $result.Details = "The following IIS application pools are not using ApplicationPoolIdentity, which may grant excessive privileges: $($vulnerablePools -join ', '). Review their configurations."
                $result.VulnerableAppPools = $vulnerablePools
            } else {
                $result.Details = "All detected IIS application pools are using ApplicationPoolIdentity."
            }
        }

    } catch {
        $result.Result = 'Error'
        $result.Details = "An error occurred while checking web process privileges: $($_.Exception.Message)"
    }

    # Remove the temporary list from the final output if not vulnerable
    if ($result.Result -ne 'Vulnerable') {
        $result.Remove('VulnerableAppPools')
    }

    return $result # Return the result object from the function
}

# Call the function and convert its output to JSON
Test-WebProcessPrivilegeRestriction | ConvertTo-Json -Compress
# W-21_IIS_Unused_Script_Mapping_Removal.ps1
# Checks for unused IIS script mappings.

function Test-IISUnusedScriptMappingRemoval {
    [CmdletBinding()]
    Param()

    $result = @{
        CheckItem = "W-21"
        Category = "Service Management"
        Result = "Good" # Default to Good
        Details = ""
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }

    # This check requires the WebAdministration module.
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        $result.Result = "Not Applicable"
        $result.Details = "IIS WebAdministration module not found. This check is not applicable."
        return $result
    }

    # Get IIS Version (simplified check, more robust would be to check registry or product version)
    # Assuming WebAdministration module is available for IIS 7.0+
    $iisVersion = 0
    if (Get-Module -ListAvailable -Name WebAdministration -ErrorAction SilentlyContinue) {
        $iisVersion = 7 # Assuming IIS 7.0 or later if WebAdministration module is present
    } else {
        # For older IIS versions (5.0/6.0), direct registry or WMI checks might be needed
        # This is a simplification for now.
        # If IISADMIN service is running but WebAdministration module is not, assume older IIS.
        if (Get-Service -Name IISADMIN -ErrorAction SilentlyContinue) {
            $iisVersion = 5 # Placeholder for IIS 5.0/6.0
        }
    }

    $vulnerableExtensions = @(".htr", ".idc", ".stm", ".shtm", ".shtml", ".printer", ".htw", ".ida", ".idq")
    $foundVulnerabilities = @()

    if ($iisVersion -ge 7) {
        # IIS 7.0 and later (Windows 2008+)
        # Check Handler Mappings and Request Filtering
        try {
            Import-Module WebAdministration -ErrorAction Stop
            $sites = Get-Website -ErrorAction SilentlyContinue
            foreach ($site in $sites) {
                # Check Handler Mappings
                $handlerMappings = Get-WebHandler -PSPath "IIS:\Sites\$($site.Name)" -ErrorAction SilentlyContinue
                foreach ($ext in $vulnerableExtensions) {
                    if ($handlerMappings | Where-Object { $_.Path -eq "*" + $ext }) {
                        $foundVulnerabilities += "Handler mapping for $($ext) found on site $($site.Name)."
                    }
                }

                # Check Request Filtering (fileExtensions)
                $requestFiltering = Get-WebConfigurationProperty -PSPath "IIS:\Sites\$($site.Name)" -Filter "system.webServer/security/requestFiltering/fileExtensions" -Name "." -ErrorAction SilentlyContinue
                foreach ($ext in $vulnerableExtensions) {
                    if ($requestFiltering.Collection | Where-Object { $_.FileExtension -eq $ext -and $_.Allowed -eq $true }) {
                        $foundVulnerabilities += "Request filtering allows $($ext) on site $($site.Name)."
                    }
                }
            }
        } catch {
            $result.Result = "Error"
            $result.Details = "Error checking IIS 7.0+ configuration: $($_.Exception.Message)"
            return $result
        }
    } elseif ($iisVersion -ge 5) {
        # IIS 5.0/6.0 (Windows 2000/2003)
        # This requires interacting with the IIS Metabase directly, which is more complex.
        # For simplicity, I will just return "Manual Check Required" for these versions.
        $result.Result = "Manual Check Required"
        $result.Details = "IIS 5.0/6.0 detected. Manual check required for script mappings as direct PowerShell cmdlets are limited. Refer to guide for manual steps."
        return $result
    } else {
        $result.Result = "Good"
        $result.Details = "IIS Web Server is not detected. This check is not applicable."
        return $result
    }

    if ($foundVulnerabilities.Count -gt 0) {
        $result.Result = "Vulnerable"
        $result.Details = "Found unused script mappings: $($foundVulnerabilities -join '; ')"
    } else {
        $result.Result = "Good"
        $result.Details = "No vulnerable unused script mappings found."
    }

    return $result
}

Test-IISUnusedScriptMappingRemoval | ConvertTo-Json -Depth 100
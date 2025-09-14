<#
.SYNOPSIS
    This script configures a Windows Server with a vulnerable environment for security diagnostics testing.
    It should be run after install_features.ps1.
#>

# Set script-level error action to stop on terminating errors
$ErrorActionPreference = 'Stop'

# Import ServerManager module for feature management cmdlets
Import-Module ServerManager -ErrorAction SilentlyContinue

# --- Function Definitions ---

function Configure-FtpSite {
    Write-Host "Configuring default FTP site..."
    try {
        $ftpRoot = "C:\inetpub\ftproot"
        if (-not (Test-Path $ftpRoot)) {
            New-Item -Path $ftpRoot -Type Directory -Force
        }
        
        New-WebFtpSite -Name "Default FTP Site" -PhysicalPath $ftpRoot -Force -ErrorAction Stop
        Write-Host "Default FTP site created successfully."
    } catch {
        Write-Error "Failed to configure FTP site: $_"
    }
}

function Configure-FtpTestFile {
    Write-Host "Creating a test file in the FTP root directory..."
    try {
        $ftpRoot = "C:\inetpub\ftproot"
        if (Test-Path $ftpRoot) {
            "This is a test file created for FTP diagnostics." | Out-File -FilePath (Join-Path $ftpRoot "ftp_test_file.txt") -Encoding UTF8 -Force
            Write-Host "  - Successfully created 'ftp_test_file.txt' in '$ftpRoot'."
        } else {
            Write-Warning "  - FTP root directory '$ftpRoot' not found. Skipping test file creation."
        }
    } catch {
        Write-Error "Failed to create FTP test file: $_"
    }
}

function Create-DefaultIisWebsite {
    Write-Host "Ensuring Default Web Site exists..."
    try {
        if (-not (Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue)) {
            # Create the default website if it doesn't exist
            # This assumes the Web-Server feature is already installed
            New-Website -Name "Default Web Site" -PhysicalPath "C:\inetpub\wwwroot" -Port 80 -Force -ErrorAction Stop
            Write-Host "  - Default Web Site created successfully."
        } else {
            Write-Host "  - Default Web Site already exists."
        }
    } catch {
        Write-Error "Failed to create Default Web Site: $_"
    }
}

function Configure-VulnerableShare {
    Write-Host "Configuring vulnerable share for W-07..."
    try {
        $sharePath = "C:\VulnerableShare"
        $shareName = "VulnerableShare"

        # Create the directory if it doesn't exist
        if (-not (Test-Path $sharePath)) {
            New-Item -Path $sharePath -Type Directory -Force
            Write-Host "  - Created directory: $sharePath"
        } else {
            Write-Host "  - Directory already exists: $sharePath"
        }

        # Create the share
        if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
            New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Everyone" -ErrorAction Stop
            Write-Host "  - Created vulnerable share: $shareName"
        } else {
            Write-Host "  - Share '$shareName' already exists."
            # Ensure 'Everyone' has FullAccess if it already exists
            Grant-SmbShareAccess -Name $shareName -AccountName "Everyone" -AccessRight Full -Force -ErrorAction Stop
            Write-Host "  - Ensured 'Everyone' has FullAccess on share: $shareName"
        }
    } catch {
        Write-Error "Failed to configure vulnerable share: $_"
    }
}

function Configure-VulnerableCgiDirectory {

    Write-Host "Configuring vulnerable CGI directory for W-12..."
    try {
        $cgiPath = "C:\inetpub\scripts"

        # Create the directory if it doesn't exist
        if (-not (Test-Path $cgiPath)) {
            New-Item -Path $cgiPath -Type Directory -Force | Out-Null
            Write-Host "  - Created directory: $cgiPath"
        } else {
            Write-Host "  - Directory already exists: $cgiPath"
        }

        # Grant Everyone Write access
        $acl = Get-Acl $cgiPath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Write", "ContainerInherit, ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($accessRule)
        Set-Acl $cgiPath $acl
        Write-Host "  - Granted 'Everyone' Write access to $cgiPath."

    } catch {
        Write-Error "Failed to configure vulnerable CGI directory: $_"
    }
}

function Configure-VulnerableParentPathAccess {
    Write-Host "Configuring vulnerable parent path access for W-13..."
    try {
        # Ensure WebAdministration module is loaded
        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            Write-Host "  - WebAdministration module not found. IIS might not be installed or module not available."
            return
        }
        Import-Module WebAdministration -ErrorAction Stop
        Write-Host "  - WebAdministration module loaded."

        Write-Host "  - Attempting to globally unlock 'system.webServer/asp' section..."
        try {
            Set-WebConfiguration -filter "system.webServer/asp" -metadata overrideMode -value "Allow" -ErrorAction Stop
            Write-Host "    - Successfully globally unlocked 'system.webServer/asp' section."
        } catch {
            Write-Warning "  - Could not globally unlock 'system.webServer/asp' section: $($_.Exception.Message)"
        }

        $websites = Get-WebSite -ErrorAction SilentlyContinue
        if ($null -eq $websites) {
            Write-Host "  - No IIS websites found to configure."
            return
        }
        Write-Host "  - Found $($websites.Count) IIS websites."

        foreach ($site in $websites) {
            Write-Host "  - Attempting to configure site: $($site.Name)"
            if ($site.Name -eq "Default FTP Site") {
                Write-Host "  - Skipping FTP site: $($site.Name) as parent path access is not applicable."
                continue
            }
            
            try {
                # Check current state before attempting to set
                $currentAspConfig = Get-WebConfigurationProperty -PSPath "IIS:\Sites\$($site.Name)" -Filter 'system.webServer/asp' -Name '*' -ErrorAction SilentlyContinue
                Write-Host "    - Current EnableParentPaths for $($site.Name): $($currentAspConfig.EnableParentPaths)"

                # Enable EnableParentPaths for the ASP configuration of the site
                Set-WebConfigurationProperty -PSPath "IIS:\Sites\$($site.Name)" -Filter 'system.webServer/asp' -Name 'enableParentPaths' -Value $true -ErrorAction Stop
                Write-Host "    - Successfully set EnableParentPaths to $true for site: $($site.Name)"

                # Verify after setting
                $newAspConfig = Get-WebConfigurationProperty -PSPath "IIS:\Sites\$($site.Name)" -Filter 'system.webServer/asp' -Name '*' -ErrorAction SilentlyContinue
                Write-Host "    - Verified EnableParentPaths for $($site.Name) is now: $($newAspConfig.EnableParentPaths)"

            } catch {
                Write-Warning "  - Could not enable parent path access for site $($site.Name): $($_.Exception.Message)"
            }
        }
        Write-Host "Vulnerable parent path access configured successfully."
    } catch {
        Write-Error "Failed to configure vulnerable parent path access: $_"
    }
}

function Configure-AppCmdHandler {
    Write-Host "Configuring IIS handlers for all websites..."
    try {
        # Ensure WebAdministration module is loaded
        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            Write-Host "  - WebAdministration module not found. IIS might not be installed or module not available."
            return
        }
        Import-Module WebAdministration -ErrorAction Stop

        $sites = Get-Website
        if ($null -eq $sites) {
            Write-Host "  - No IIS websites found to configure."
            return
        }
        Write-Host "  - Found $($sites.Count) sites."

        # ASA handler mapping properties
        $asaHandlerProperties = @{
            name            = "asa-handler-vuln"
            path            = "*.asa"
            verb            = "*"
            modules         = "IsapiModule"
            scriptProcessor = "$env:windir\system32\inetsrv\asp.dll"
            resourceType    = "File"
            requireAccess   = "Script"
        }

        # ASAX handler mapping properties
        $asaxHandlerProperties = @{
            name            = "asax-handler-vuln"
            path            = "*.asax"
            verb            = "*"
            modules         = "IsapiModule"
            scriptProcessor = "$env:windir\system32\inetsrv\asp.dll"
            resourceType    = "File"
            requireAccess   = "Script"
        }

        foreach ($site in $sites) {
            $targetSiteName = $site.Name
            
            # Check if the site has HTTP bindings
            $isHttpSite = $false
            foreach($binding in $site.bindings.collection) {
                if($binding.protocol -like "http*") {
                    $isHttpSite = $true
                    break
                }
            }

            if (-not $isHttpSite) {
                Write-Host "--- Skipping non-HTTP site: $targetSiteName ---"
                continue
            }

            Write-Host "--- Configuring handlers for site: $targetSiteName ---"

            # Remove existing handlers to prevent conflicts
            $handlersToRemove = @("asa-handler-vuln", "asax-handler-vuln")
            foreach ($handlerName in $handlersToRemove) {
                $existingHandler = Get-WebConfiguration -pspath "IIS:\Sites\$targetSiteName" -filter "system.webServer/handlers/add[@name='$handlerName']" -ErrorAction SilentlyContinue
                if ($existingHandler) {
                    Write-Host "  - Removing existing handler mapping: $handlerName from $targetSiteName"
                    Remove-WebConfigurationProperty -pspath "IIS:\Sites\$targetSiteName" -filter "system.webServer/handlers" -name "." -atElement @{name=$handlerName} -ErrorAction Stop
                    Write-Host "  - Successfully removed handler mapping: $handlerName from $targetSiteName"
                }
            }

            # Add .asa handler
            Write-Host "  - Adding '.asa' handler mapping to '$targetSiteName' site."
            Add-WebConfigurationProperty -pspath "IIS:\Sites\$targetSiteName" -filter "system.webServer/handlers" -name "." -value $asaHandlerProperties -ErrorAction Stop
            Write-Host "  - '.asa' handler mapping added successfully to '$targetSiteName'."

            # Add .asax handler
            Write-Host "  - Adding '.asax' handler mapping to '$targetSiteName' site."
            Add-WebConfigurationProperty -pspath "IIS:\Sites\$targetSiteName" -filter "system.webServer/handlers" -name "." -value $asaxHandlerProperties -ErrorAction Stop
            Write-Host "  - '.asax' handler mapping added successfully to '$targetSiteName'."
        }

        Write-Host "IIS handlers configured for all applicable sites successfully."
    } catch {
        Write-Error "Failed to configure IIS handlers: $_"
    }
}

function Configure-AnonymousFtp {
    Write-Host "Configuring Anonymous FTP for W-27...";
    try {
        # Ensure WebAdministration module is loaded
        if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
            Write-Host "  - WebAdministration module not found. IIS might not be installed or module not available.";
            return;
        }
        Import-Module WebAdministration -ErrorAction Stop;

        Write-Host "  - Enabling anonymous authentication for FTP on 'Default FTP Site'...";
        Set-ItemProperty -Path 'IIS:\Sites\Default FTP Site' -Name 'ftpServer.security.authentication.anonymousAuthentication.enabled' -Value $true
        Write-Host "  - Anonymous authentication for FTP enabled successfully on 'Default FTP Site'.";

        Write-Host "  - Ensuring basic authentication element exists for FTP on 'Default FTP Site' before disabling...";
        $basicAuthExists = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.ftpServer/security/authentication/basicAuthentication" -name "enabled" -Location "Default FTP Site" -ErrorAction SilentlyContinue;
        if (-not $basicAuthExists) {
            Write-Host "  - Basic authentication element not found, adding it...";
            Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.ftpServer/security/authentication" -name "." -value @{name="basicAuthentication"; enabled="false"} -Location "Default FTP Site" -ErrorAction Stop;
            Write-Host "  - Basic authentication element added and disabled.";
        } else {
            Write-Host "  - Disabling basic authentication for FTP on 'Default FTP Site'...";
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.ftpServer/security/authentication/basicAuthentication" -name "enabled" -value "false" -Location "Default FTP Site" -ErrorAction Stop;
            Write-Host "  - Basic authentication for FTP disabled successfully on 'Default FTP Site'.";
        }

    } catch {
        Write-Error "Failed to configure Anonymous FTP: $_";
    }
}

function Configure-VulnerableDnsZoneTransfer {
    Write-Host "Configuring vulnerable DNS Zone Transfer for W-29..."
    try {
        # Ensure DNS Server module is loaded
        if (-not (Get-Module -ListAvailable -Name DnsServer)) {
            Write-Host "  - DnsServer module not found. DNS Server role might not be installed or module not available."
            return
        }
        Import-Module DnsServer -ErrorAction Stop
        Write-Host "  - DnsServer module loaded."

        Add-DnsServerPrimaryZone -Name "lab.local" -ZoneFile "lab.local.dns"
        Write-Host "  - Created primary DNS zone 'lab.local'."

        # [2단계] 아래 명령어를 실행하여 영역 전송을 '모든 서버에 허용'으로 설정합니다.
        Set-DnsServerPrimaryZone -Name "lab.local" -SecureSecondaries "TransferAnyServer"
        Write-Host "  - Configured DNS Zone Transfer to 'TransferAnyServer' for zone 'lab.local'."

        

    } catch {
        Write-Error "Failed to configure vulnerable DNS Zone Transfer: $_"
    }
}

# --- Main Script Execution ---

Configure-FtpSite

Configure-FtpTestFile

Configure-AnonymousFtp

Create-DefaultIisWebsite

Configure-VulnerableShare

Configure-VulnerableCgiDirectory

Configure-AppCmdHandler

Configure-VulnerableParentPathAccess

Configure-VulnerableDnsZoneTransfer


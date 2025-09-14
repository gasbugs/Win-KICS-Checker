<#
.SYNOPSIS
    This script provisions a Windows Server for security diagnostics testing.
    It performs the following actions:
    1. Configures WinRM for HTTPS communication.
    2. Installs required Windows Features (IIS, FTP, SNMP, DNS).
    3. Creates a default FTP site for testing.
    4. Installs necessary PowerShell modules (PowerShellGet, IISAdministration).
    5. Verifies the installation and status of all components.
#>

# Set script-level error action to stop on terminating errors
$ErrorActionPreference = 'Stop'

# --- Function Definitions ---

function Configure-WinRM {
    Write-Host "Configuring WinRM for HTTPS..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $url = "https://raw.githubusercontent.com/ansible/ansible-documentation/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
        $file = Join-Path $env:TEMP "ConfigureRemotingForAnsible.ps1"

        (New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
        powershell.exe -ExecutionPolicy Bypass -File $file -ErrorAction Stop
        Write-Host "WinRM configured successfully."
    } catch {
        Write-Error "Failed to configure WinRM: $_"
        exit 1
    }
}

function Install-WindowsFeatures {
    param(
        [string[]]$FeatureNames
    )
    
    Write-Host "Installing Windows Features: $($FeatureNames -join ', ')..."
    foreach ($feature in $FeatureNames) {
        try {
            if (-not (Get-WindowsFeature -Name $feature).Installed) {
                Install-WindowsFeature -Name $feature -IncludeManagementTools -ErrorAction Stop
                Write-Host "  - Successfully installed $feature."
            } else {
                Write-Host "  - $feature is already installed."
            }
        } catch {
            Write-Error "Failed to install feature '$feature': $_"
        }
    }
}

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

function Install-PowerShellModules {
    Write-Host "Installing required PowerShell modules..."
    try {
        # Ensure PowerShellGet is available
        if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
            Write-Host "  - PowerShellGet not found. Installing..."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Install-Module -Name PowerShellGet -Force -AllowClobber
            Write-Warning "PowerShellGet was installed. Please re-run this script in a new PowerShell session."
            exit
        }

        # Install IISAdministration
        if (-not (Get-Module -ListAvailable -Name IISAdministration)) {
            Write-Host "  - Installing IISAdministration module..."
            Install-Module -Name IISAdministration -Repository PSGallery -Force -Scope AllUsers
        } else {
            Write-Host "  - IISAdministration module is already installed."
        }
        Import-Module IISAdministration -ErrorAction SilentlyContinue
    } catch {
        Write-Error "Failed to install PowerShell modules: $_"
    }
}

function Verify-Installation {
    Write-Host "================================================"
    Write-Host "Verifying installation status..."
    Write-Host "================================================"

    $features = @("Web-Server", "Web-Ftp-Server", "SNMP-Service", "DNS")
    foreach ($featureName in $features) {
        $feature = Get-WindowsFeature -Name $featureName
        Write-Host "$($feature.DisplayName) Installed: $($feature.Installed)"
        if ($feature.Installed) {
            $serviceName = switch ($featureName) {
                "Web-Server" { "W3SVC" }
                "Web-Ftp-Server" { "FTPSVC" }
                "SNMP-Service" { "SNMP" }
                "DNS" { "DNS" }
            }
            if ($serviceName) {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    Write-Host "  - Service '$($serviceName)' Status: $($service.Status)"
                } else {
                    Write-Host "  - Service '$($serviceName)' Status: Not Found"
                }
            }
        }
    }
    
    $iisAdminModule = Get-Module -ListAvailable -Name IISAdministration
    if ($iisAdminModule) {
        Write-Host "IISAdministration Module Installed: True (Version: $($iisAdminModule.Version))"
    } else {
        Write-Host "IISAdministration Module Installed: False"
    }
    
    Write-Host "================================================"
    Write-Host "Verification complete."
    Write-Host "================================================"
}


# --- Main Script Execution ---

Configure-WinRM

Install-WindowsFeatures -FeatureNames @("Web-Server", "Web-Ftp-Server", "SNMP-Service", "DNS", "Telnet-Client")

# Set W3SVC to start automatically
try {
    Set-Service -Name W3SVC -StartupType Automatic
} catch {
    Write-Warning "Could not set W3SVC startup type. A reboot might be required after feature installation."
}

Configure-FtpSite

Configure-VulnerableShare

Configure-VulnerableCgiDirectory

Configure-VulnerableParentPathAccess

Install-PowerShellModules

Verify-Installation
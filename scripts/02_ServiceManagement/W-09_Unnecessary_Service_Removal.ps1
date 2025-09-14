# W-09: Remove Unnecessary Services
# Checks for generally unnecessary services that are running.

$ErrorActionPreference = 'Stop'

$result = @{
    CheckItem = 'W-09'
    Category = 'Service Management'
    Result = 'Good'
    Details = 'No generally unnecessary services were found running.'
    Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    RunningUnnecessaryServices = @()
    ManualReviewServices = @()
}

try {
    # List of services generally considered unnecessary for most server roles
    # Excludes highly critical or context-dependent services for direct 'Vulnerable' flagging
    $unnecessaryServices = @(
        "Alerter",
        "ClipSrv", # Clipbook
        "Browser", # Computer Browser
        "ErrReport", # Error reporting Service
        "HidServ", # Human Interface Device Access
        "ImapiService", # IMAPI CD-Burning COM Service
        "Messenger",
        "mnmsrvc", # NetMeeting Remote Desktop Sharing
        "Portable Device Enumerator Service", # Portable Media Serial Number
        "RemoteRegistry",
        "SimpTcp", # Simple TCP/IP Services
        "WZCSVC" # Wireless Zero Configuration
    )

    # Services that are often unnecessary but require careful manual review due to context
    $contextDependentServices = @(
        "wuauserv", # Automatic Updates
        "CryptSvc", # Cryptographic Services (very critical, usually needed)
        "Dhcp", # DHCP Client
        "TrkSvr", # Distributed Link Tracking Server
        "TrkWks", # Distributed Link Tracking Client
        "Dnscache", # DNS Client
        "Spooler" # Print Spooler
    )

    $foundRunningUnnecessary = @()
    foreach ($serviceName in $unnecessaryServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            $foundRunningUnnecessary += "$($service.DisplayName) (Name: $($service.Name), Status: $($service.Status), StartMode: $($service.StartType))"
        }
    }

    if ($foundRunningUnnecessary.Count -gt 0) {
        $result.Result = 'Vulnerable'
        $result.Details = "The following generally unnecessary services are running: $($foundRunningUnnecessary -join '; ')."
        $result.RunningUnnecessaryServices = $foundRunningUnnecessary
    }

    # Add a note about context-dependent services for manual review
    $foundContextDependent = @()
    foreach ($serviceName in $contextDependentServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $foundContextDependent += "$($service.DisplayName) (Name: $($service.Name), Status: $($service.Status), StartMode: $($service.StartType))"
        }
    }
    if ($foundContextDependent.Count -gt 0) {
        $result.ManualReviewServices = $foundContextDependent
        if ($result.Result -eq 'Good') {
            $result.Details = "No generally unnecessary services were found running. However, the following services require manual review based on system role: $($foundContextDependent -join '; ')."
        } else {
            $result.Details += " Additionally, the following services require manual review based on system role: $($foundContextDependent -join '; ')."
        }
    }


} catch {
    $result.Result = 'Error'
    $result.Details = "An error occurred while checking services: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Compress

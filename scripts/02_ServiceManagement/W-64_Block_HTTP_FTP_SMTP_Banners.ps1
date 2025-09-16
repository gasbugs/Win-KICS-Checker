<#
.SYNOPSIS
    Checks if HTTP, FTP, and SMTP service banners are hidden or non-descriptive.

.DESCRIPTION
    This script verifies the banners of running HTTP (IIS), FTP, and SMTP services.
    - For FTP (Port 21) and SMTP (Port 25), it attempts to connect and read the service banner.
      If the banner reveals specific software information (e.g., 'Microsoft FTP Service'), it is flagged as 'Vulnerable'.
    - For IIS FTP sites, it enumerates configured sites and checks their banners on their respective bindings.
    - For HTTP (IIS), it enumerates configured sites and checks their 'Server' headers.
    If a service is not running or its banner/header is non-descriptive, it is considered 'Good'.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W64BlockHTTPFTPSMTPBanners {
    [CmdletBinding()]
    param()

    <#
.SYNOPSIS
    Connects to a local TCP port and retrieves the initial banner message.

.DESCRIPTION
    This function attempts to establish a TCP connection to 127.0.0.1 on a specified port.
    It has a 2-second timeout for connecting and a 2-second timeout for reading.
    If a banner message is received, it is returned as a string.
    Handles connection errors, timeouts, and empty banners.

.PARAMETER Port
    The local port number to connect to.

.OUTPUTS
    A string containing the banner message, an error message, or an empty string if no banner is received.
#>
function Get-Banner($port, $ipAddress = "127.0.0.1") {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectResult = $tcpClient.BeginConnect($ipAddress, $port, $null, $null)
        
        # Wait for connection with a timeout
        $waitHandle = $connectResult.AsyncWaitHandle
        if ($waitHandle.WaitOne(2000, $false)) { # 2-second timeout
            $tcpClient.EndConnect($connectResult)
        } else {
            $tcpClient.Close()
            return "Connection timed out."
        }

        if ($tcpClient.Connected) {
            $stream = $tcpClient.GetStream()
            $stream.ReadTimeout = 2000 # 2-second read timeout
            $buffer = New-Object byte[] 1024
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -gt 0) {
                $banner = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead).Trim()
                return $banner
            }
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        return "Error connecting or reading from port {0}: {1}" -f $port, $errorMessage
    }
    finally {
        if ($tcpClient) {
            $tcpClient.Close()
        }
    }
    return ""
}

    $checkItem = "W-64"
    $category = "Service Management"
    $overallResult = "Good"
    $details = @()

    try {
        # 1. Check HTTP (IIS)
        $details += "`n--- Checking HTTP Services ---"
        $iisService = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
        if ($iisService -and $iisService.Status -eq 'Running') {
            $details += "IIS (HTTP) service is running. Performing simple HTTP banner check on 127.0.0.1:80..."
            try {
                $uri = "http://127.0.0.1:80"
                $response = Invoke-WebRequest -Uri $uri -Method GET -TimeoutSec 5 -ErrorAction SilentlyContinue
                
                $allResponseText = ""
                # Add headers to the search string
                foreach ($header in $response.Headers.GetEnumerator()) {
                    $allResponseText += "$($header.Name): $($header.Value)`n"
                }
                # Add body content to the search string
                if ($response.Content) {
                    $allResponseText += $response.Content
                }
                
                if ($allResponseText -match "iis") { # Case-insensitive match
                    $details += "  - HTTP response (headers and body) from $uri contains 'iis' string. (Vulnerable)"
                    $overallResult = "Vulnerable"
                } else {
                    $details += "  - HTTP response (headers and body) from $uri does not reveal specific 'iis' information. (Good)"
                }
            }
            catch {
                $details += "  - Could not retrieve HTTP response from {0}: {1}" -f $uri, $_.Exception.Message
            }
        } else {
            $details += "IIS (HTTP) service is not running or not installed. (Good)"
        }

        # 2. Check FTP (Generic FTPSVC and IIS FTP Sites)
        $details += "`n--- Checking FTP Services ---"

        # Check generic FTPSVC
        $ftpService = Get-Service -Name FTPSVC -ErrorAction SilentlyContinue
        if ($ftpService -and $ftpService.Status -eq 'Running') {
            $details += "Generic FTP service (FTPSVC) is running. Checking banner on 127.0.0.1:21..."
            $ftpBanner = Get-Banner -ipAddress "127.0.0.1" -port 21
            if ($ftpBanner) {
                $details += "  - Generic FTP Banner: $ftpBanner"
                if ($ftpBanner -match "Microsoft FTP Service" -or $ftpBanner -match "FTP") {
                    $details += "  - Generic FTP banner reveals specific software information. (Vulnerable)"
                    $overallResult = "Vulnerable"
                } else {
                    $details += "  - Generic FTP banner is generic or non-descriptive. (Good)"
                }
            } else {
                $details += "  - Could not retrieve generic FTP banner or banner is empty. (Good)"
            }
        } else {
            $details += "Generic FTP service (FTPSVC) is not running or not installed. (Good)"
        }

        # Check IIS FTP sites
        try {
            Import-Module WebAdministration -ErrorAction SilentlyContinue
            if (-not (Get-Module -Name WebAdministration)) {
                $details += "WebAdministration module not loaded. Cannot check IIS FTP sites."
            } else {
                $iisFtpSites = Get-WebSite | Where-Object { $_.Bindings.Collection | Where-Object { $_.Protocol -eq "ftp" } }

                if ($iisFtpSites.Count -gt 0) {
                    $details += "Found IIS FTP sites. Checking their banners..."
                    foreach ($site in $iisFtpSites) {
                        $details += "  - Checking IIS FTP Site: $($site.Name)"
                        if ($site.State -eq "Started") {
                            $ftpBindings = $site.Bindings.Collection | Where-Object { $_.Protocol -eq "ftp" }
                            if ($ftpBindings.Count -gt 0) {
                                foreach ($binding in $ftpBindings) {
                                    $ipAddress = if ($binding.IPAddress -eq "*") { "127.0.0.1" } else { $binding.IPAddress }
                                    $port = $binding.Port
                                    $details += "    - Binding: ftp://{0}:{1}" -f $ipAddress, $port
                                    $iisFtpBanner = Get-Banner -ipAddress $ipAddress -port $port
                                    if ($iisFtpBanner) {
                                        $details += "      - IIS FTP Banner: $iisFtpBanner"
                                        if ($iisFtpBanner -match "Microsoft FTP Service" -or $iisFtpBanner -match "FTP") {
                                            $details += "      - IIS FTP banner reveals specific software information. (Vulnerable)"
                                            $overallResult = "Vulnerable"
                                        } else {
                                            $details += "      - IIS FTP banner is generic or non-descriptive. (Good)"
                                        }
                                    } else {
                                        $details += "      - Could not retrieve IIS FTP banner or banner is empty. (Good)"
                                    }
                                }
                            } else {
                                $details += "    - No FTP bindings found for site $($site.Name)."
                            }
                        } else {
                            $details += "    - IIS FTP Site $($site.Name) is stopped. (Good)"
                        }
                    }
                } else {
                    $details += "No IIS FTP sites found. (Good)"
                }
            }
        }
        catch {
            $details += "An error occurred while checking IIS FTP sites: {0}" -f $_.Exception.Message
            if ($overallResult -ne "Vulnerable") { $overallResult = "Error" } # Don't overwrite Vulnerable
        }

        # 3. Check SMTP
        $details += "`n--- Checking SMTP Service ---"
        $smtpService = Get-Service -Name SMTPSVC -ErrorAction SilentlyContinue
        if ($smtpService -and $smtpService.Status -eq 'Running') {
            $details += "SMTP service is running. Checking banner on 127.0.0.1:25..."
            $smtpBanner = Get-Banner -ipAddress "127.0.0.1" -port 25
            if ($smtpBanner) {
                $details += "  - SMTP Banner: $smtpBanner"
                # E.g., "220 machinename.domain Microsoft ESMTP MAIL Service"
                if ($smtpBanner -match "Microsoft" -or $smtpBanner -match "ESMTP" -or $smtpBanner -match "SMTP") {
                    $details += "  - SMTP banner reveals specific software information. (Vulnerable)"
                    if ($overallResult -ne "Vulnerable") { $overallResult = "Vulnerable" }
                } else {
                    $details += "  - SMTP banner is generic or non-descriptive. (Good)"
                }
            } else {
                $details += "  - Could not retrieve SMTP banner or banner is empty. (Good)"
            }
        } else {
            $details += "SMTP service is not running or not installed. (Good)"
        }

        if ($details.Count -eq 0) {
            $details = "No relevant services found to check."
        }

    }
    catch {
        $overallResult = "Error"
        $details = "An error occurred: {0}" -f $_.Exception.Message
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $overallResult
        Details = ($details | Out-String).Trim()
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W64BlockHTTPFTPSMTPBanners
<#
.SYNOPSIS
    Checks if HTTP, FTP, and SMTP service banners are hidden.

.DESCRIPTION
    This script verifies the status of HTTP (IIS), FTP, and SMTP services.
    If these services are running, it indicates that their banners require manual verification
    as programmatic checking of banners can be complex and version-dependent.
    If a service is not running, its banner is not exposed, which is considered good.

.OUTPUTS
    A JSON object indicating the check item, category, result, and details.
#>

function Test-W64BlockHTTPFTPSMTPBanners {
    [CmdletBinding()]
    param()
    
    $checkItem = "W-64"
    $category = "Service Management"
    $result = "Good"
    $details = @()

    try {
        # Check HTTP (IIS) - covered by W-59, but can add a note here
        $iisService = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
        if ($iisService -and $iisService.Status -eq 'Running') {
            $details += "IIS (HTTP) service is running. HTTP banner information requires manual verification (refer to W-59 for header checks)."
            $result = "Manual Check Required"
        } else {
            $details += "IIS (HTTP) service is not running or not installed. (Good)"
        }

        # Check FTP
        $ftpService = Get-Service -Name MSFTPSVC -ErrorAction SilentlyContinue
        if ($ftpService -and $ftpService.Status -eq 'Running') {
            $details += "FTP service is running. FTP banner information requires manual verification."
            $result = "Manual Check Required"
        } else {
            $details += "FTP service is not running or not installed. (Good)"
        }

        # Check SMTP
        $smtpService = Get-Service -Name SMTPSVC -ErrorAction SilentlyContinue
        if ($smtpService -and $smtpService.Status -eq 'Running') {
            $details += "SMTP service is running. SMTP banner information requires manual verification."
            $result = "Manual Check Required"
        } else {
            $details += "SMTP service is not running or not installed. (Good)"
        }

        if ($details.Count -eq 0) {
            $details = "No relevant services found or running."
        } else {
            $details = ($details | Out-String).Trim()
        }

    }
    catch {
        $result = "Error"
        $details = "An error occurred while checking service banners: $($_.Exception.Message)"
    }

    $output = @{
        CheckItem = $checkItem
        Category = $category
        Result = $result
        Details = $details
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    # Convert to JSON and output
    $output | ConvertTo-Json -Depth 4
}

# Execute the function
Test-W64BlockHTTPFTPSMTPBanners

# W-33: HTTP/FTP/SMTP 배너 차단
function Test-W33 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem = "W-33"
        Category  = "서비스 관리"
        Result    = "Good"
        Details   = ""
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    function Get-Banner {
        param([string]$Host_, [int]$Port, [int]$TimeoutMs = 3000)
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $client.Connect($Host_, $Port)
            $stream = $client.GetStream()
            $stream.ReadTimeout = $TimeoutMs
            $buffer = New-Object byte[] 1024
            $read = $stream.Read($buffer, 0, $buffer.Length)
            $client.Close()
            return [System.Text.Encoding]::ASCII.GetString($buffer, 0, $read)
        } catch {
            return $null
        }
    }

    try {
        $issues = @()

        # HTTP 배너 점검
        $w3svc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
        if ($w3svc -and $w3svc.Status -eq 'Running') {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
                $server = $response.Headers["Server"]
                if ($server -and $server -match 'IIS|Microsoft') {
                    $issues += "HTTP banner reveals server info: $server"
                }
            } catch {}
        }

        # FTP 배너 점검
        $ftpsvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
        if ($ftpsvc -and $ftpsvc.Status -eq 'Running') {
            $ftpBanner = Get-Banner -Host_ "127.0.0.1" -Port 21
            if ($ftpBanner -and $ftpBanner -match 'Microsoft FTP|FTP') {
                $issues += "FTP banner reveals server info: $($ftpBanner.Trim())"
            }
        }

        # SMTP 배너 점검
        $smtpsvc = Get-Service -Name "SMTPSVC" -ErrorAction SilentlyContinue
        if ($smtpsvc -and $smtpsvc.Status -eq 'Running') {
            $smtpBanner = Get-Banner -Host_ "127.0.0.1" -Port 25
            if ($smtpBanner -and $smtpBanner -match 'Microsoft|ESMTP') {
                $issues += "SMTP banner reveals server info: $($smtpBanner.Trim())"
            }
        }

        if ($issues.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = $issues -join "; "
        } elseif (-not $w3svc -and -not $ftpsvc -and -not $smtpsvc) {
            $result.Result  = "Not Applicable"
            $result.Details = "No HTTP/FTP/SMTP services are running."
        } else {
            $result.Details = "Service banners do not reveal identifying information."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking service banners: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W33

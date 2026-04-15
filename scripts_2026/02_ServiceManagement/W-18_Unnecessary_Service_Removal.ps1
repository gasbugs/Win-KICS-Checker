# W-18: 불필요한 서비스 제거
function Test-W18 {
    [CmdletBinding()]
    param()

    $result = @{
        CheckItem                = "W-18"
        Category                 = "서비스 관리"
        Result                   = "Good"
        Details                  = ""
        RunningUnnecessaryServices = @()
        ManualReviewServices     = @()
        Timestamp                = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $unnecessaryServices = @(
            "Alerter", "ClipSrv", "Browser", "ErrReport", "HidServ",
            "ImapiService", "Messenger", "mnmsrvc",
            "Portable Device Enumerator Service", "RemoteRegistry",
            "SimpTcp", "WZCSVC"
        )
        $reviewServices = @(
            "wuauserv", "CryptSvc", "Dhcp", "TrkSvr", "TrkWks", "Dnscache", "Spooler"
        )

        foreach ($svcName in $unnecessaryServices) {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                $result.RunningUnnecessaryServices += "$($svc.Name) ($($svc.DisplayName))"
            }
        }

        foreach ($svcName in $reviewServices) {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                $result.ManualReviewServices += "$($svc.Name) ($($svc.DisplayName))"
            }
        }

        if ($result.RunningUnnecessaryServices.Count -gt 0) {
            $result.Result  = "Vulnerable"
            $result.Details = "Unnecessary services running: $($result.RunningUnnecessaryServices -join '; ')"
        } elseif ($result.ManualReviewServices.Count -gt 0) {
            $result.Result  = "Manual Check Required"
            $result.Details = "Context-dependent services running: $($result.ManualReviewServices -join '; ')"
        } else {
            $result.Details = "No unnecessary services are running."
        }
    }
    catch {
        $result.Result  = "Error"
        $result.Details = "An error occurred while checking services: $_"
    }

    $result | ConvertTo-Json -Depth 4
}

Test-W18

# run_all_diag_local_2026.ps1
# 2026 KICS Windows Server 취약점 진단 실행 스크립트 (로컬)

param(
    [string]$ChecksToRun = "all"
)

$ErrorActionPreference = "Continue"

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ComputerName = $env:COMPUTERNAME

# --- Log setup ---
$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFileName = "diagnostic_2026_log_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName)_local.log"
$logFilePath = Join-Path $logDir $logFileName
Start-Transcript -Path $logFilePath

Write-Host "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Project Root: $PSScriptRoot"
Write-Host "Target Computer: $ComputerName (local)"
Write-Host "Standard: 2026 KICS (64 items)"

# Read common functions content once
$commonFunctionsPath = "$PSScriptRoot\scripts_2026\common\common_functions.ps1"
if (Test-Path $commonFunctionsPath) {
    $commonFunctionsContent = Get-Content $commonFunctionsPath | Out-String
    Write-Host "Common functions loaded."
} else {
    Write-Warning "Common functions file not found: $commonFunctionsPath"
    $commonFunctionsContent = ""
}

# List of all 2026 diagnostic scripts (W-01 to W-64)
$allAvailableScripts = @(
    "scripts_2026\01_AccountManagement\W-01_Administrator_Rename.ps1",
    "scripts_2026\01_AccountManagement\W-02_Guest_Account_Disable.ps1",
    "scripts_2026\01_AccountManagement\W-03_Unnecessary_Account_Removal.ps1",
    "scripts_2026\01_AccountManagement\W-04_Account_Lockout_Threshold.ps1",
    "scripts_2026\01_AccountManagement\W-05_Reversible_Encryption_Disable.ps1",
    "scripts_2026\01_AccountManagement\W-06_Admin_Group_Min_Users.ps1",
    "scripts_2026\01_AccountManagement\W-07_Everyone_Anonymous_Permissions.ps1",
    "scripts_2026\01_AccountManagement\W-08_Account_Lockout_Duration.ps1",
    "scripts_2026\01_AccountManagement\W-09_Password_Policy.ps1",
    "scripts_2026\01_AccountManagement\W-10_Do_Not_Display_Last_User_Name.ps1",
    "scripts_2026\01_AccountManagement\W-11_Allow_Local_Logon.ps1",
    "scripts_2026\01_AccountManagement\W-12_Disable_Anonymous_SID_Name_Translation.ps1",
    "scripts_2026\01_AccountManagement\W-13_Restrict_Blank_Passwords.ps1",
    "scripts_2026\01_AccountManagement\W-14_Restrict_Remote_Terminal_Users.ps1",
    "scripts_2026\02_ServiceManagement\W-15_User_Private_Key_Password.ps1",
    "scripts_2026\02_ServiceManagement\W-16_Share_Permission_Setting.ps1",
    "scripts_2026\02_ServiceManagement\W-17_Harddisk_Default_Share_Removal.ps1",
    "scripts_2026\02_ServiceManagement\W-18_Unnecessary_Service_Removal.ps1",
    "scripts_2026\02_ServiceManagement\W-19_IIS_Service_Check.ps1",
    "scripts_2026\02_ServiceManagement\W-20_NetBIOS_Binding_Check.ps1",
    "scripts_2026\02_ServiceManagement\W-21_FTP_Service_Check.ps1",
    "scripts_2026\02_ServiceManagement\W-22_FTP_Directory_Permission.ps1",
    "scripts_2026\02_ServiceManagement\W-23_Anonymous_FTP_Prohibition.ps1",
    "scripts_2026\02_ServiceManagement\W-24_FTP_Access_Control.ps1",
    "scripts_2026\02_ServiceManagement\W-25_DNS_Zone_Transfer.ps1",
    "scripts_2026\02_ServiceManagement\W-26_RDS_Removal.ps1",
    "scripts_2026\02_ServiceManagement\W-27_Latest_OS_Build.ps1",
    "scripts_2026\02_ServiceManagement\W-28_Terminal_Service_Encryption.ps1",
    "scripts_2026\02_ServiceManagement\W-29_SNMP_Service_Check.ps1",
    "scripts_2026\02_ServiceManagement\W-30_SNMP_Community_String.ps1",
    "scripts_2026\02_ServiceManagement\W-31_SNMP_Access_Control.ps1",
    "scripts_2026\02_ServiceManagement\W-32_DNS_Service_Check.ps1",
    "scripts_2026\02_ServiceManagement\W-33_Block_HTTP_FTP_SMTP_Banners.ps1",
    "scripts_2026\02_ServiceManagement\W-34_Telnet_Service_Disable.ps1",
    "scripts_2026\02_ServiceManagement\W-35_Remove_Unnecessary_ODBC.ps1",
    "scripts_2026\02_ServiceManagement\W-36_Remote_Terminal_Timeout.ps1",
    "scripts_2026\02_ServiceManagement\W-37_Suspicious_Scheduled_Tasks.ps1",
    "scripts_2026\03_PatchManagement\W-38_Security_Patch_Application.ps1",
    "scripts_2026\03_PatchManagement\W-39_Antivirus_Update.ps1",
    "scripts_2026\04_LogManagement\W-40_System_Logging_Setting.ps1",
    "scripts_2026\04_LogManagement\W-41_NTP_Time_Sync.ps1",
    "scripts_2026\04_LogManagement\W-42_Event_Log_Management.ps1",
    "scripts_2026\04_LogManagement\W-43_Event_Log_Access_Control.ps1",
    "scripts_2026\05_SecurityManagement\W-44_Remote_Registry_Paths.ps1",
    "scripts_2026\05_SecurityManagement\W-45_Antivirus_Installation.ps1",
    "scripts_2026\05_SecurityManagement\W-46_SAM_File_Access_Control.ps1",
    "scripts_2026\05_SecurityManagement\W-47_Screensaver_Setting.ps1",
    "scripts_2026\05_SecurityManagement\W-48_Shutdown_Without_Logon.ps1",
    "scripts_2026\05_SecurityManagement\W-49_Force_Shutdown_Remote.ps1",
    "scripts_2026\05_SecurityManagement\W-50_Audit_Failure_Shutdown.ps1",
    "scripts_2026\05_SecurityManagement\W-51_Anonymous_SAM_Enumeration.ps1",
    "scripts_2026\05_SecurityManagement\W-52_Autologon_Control.ps1",
    "scripts_2026\05_SecurityManagement\W-53_Removable_Media_Format.ps1",
    "scripts_2026\05_SecurityManagement\W-54_DoS_Defense_Registry.ps1",
    "scripts_2026\05_SecurityManagement\W-55_Prevent_Printer_Driver_Install.ps1",
    "scripts_2026\05_SecurityManagement\W-56_SMB_Session_Management.ps1",
    "scripts_2026\05_SecurityManagement\W-57_Warning_Message.ps1",
    "scripts_2026\05_SecurityManagement\W-58_Home_Directory_Permissions.ps1",
    "scripts_2026\05_SecurityManagement\W-59_LAN_Manager_Auth_Level.ps1",
    "scripts_2026\05_SecurityManagement\W-60_Secure_Channel_Encryption.ps1",
    "scripts_2026\05_SecurityManagement\W-61_File_Directory_Protection.ps1",
    "scripts_2026\05_SecurityManagement\W-62_Startup_Program_Analysis.ps1",
    "scripts_2026\05_SecurityManagement\W-63_Domain_Controller_Time_Sync.ps1",
    "scripts_2026\05_SecurityManagement\W-64_Windows_Firewall.ps1"
)

$diagnosticScripts = @()

if ($ChecksToRun.ToLower() -eq "all") {
    Write-Host "Running all 64 diagnostic checks."
} else {
    $targetCheckNumbers = [System.Collections.Generic.List[int]]::new()
    $parts = $ChecksToRun.Split(',')
    foreach ($part in $parts) {
        if ($part.Contains('-')) {
            $range = $part.Split('-')
            if ($range.Count -eq 2) {
                try {
                    $start = [int]$range[0]
                    $end = [int]$range[1]
                    $start..$end | ForEach-Object { $targetCheckNumbers.Add($_) }
                } catch {
                    Write-Warning "Invalid range specified: $part"
                }
            }
        } else {
            try {
                $targetCheckNumbers.Add([int]$part)
            } catch {
                Write-Warning "Invalid number specified: $part"
            }
        }
    }
    $uniqueTargetNumbers = $targetCheckNumbers | Sort-Object -Unique
    $diagnosticScripts = $uniqueTargetNumbers | ForEach-Object { "W-{0:D2}" -f $_ }

    Write-Host "Running selected checks: $($diagnosticScripts -join ', ')"

    if ($uniqueTargetNumbers.Count -eq 0) {
        Write-Warning "No matching diagnostic scripts found. Exiting."
        Stop-Transcript | Out-Null
        return
    }
}

$allResults = @()
$processedResultsForCsv = @()
$combinedScriptContent = $commonFunctionsContent
$combinedScriptContent += "`n`$WarningPreference = 'SilentlyContinue'`nImport-Module SmbShare -ErrorAction SilentlyContinue"

Write-Host "Starting diagnostic checks..."

foreach ($scriptPath in $allAvailableScripts) {
    if ($ChecksToRun.ToLower() -ne "all" -and $scriptPath -match "(W-\d+)") {
        $extractedPattern = $Matches[1]
        if ($diagnosticScripts -contains $extractedPattern) {
            Write-Host "Including: $extractedPattern" -ForegroundColor Green
        } else {
            continue
        }
    }

    $fullScriptPath = Join-Path $PSScriptRoot $scriptPath
    if (Test-Path $fullScriptPath) {
        $combinedScriptContent += "`n" + (Get-Content $fullScriptPath -Raw) + "`n"
    } else {
        Write-Warning "Script not found: $fullScriptPath"
    }
}

try {
    Write-Host "Executing combined script locally..."
    $executionResults = @()
    Invoke-Expression $combinedScriptContent | ForEach-Object {
        $jsonOutput = $_ | ConvertFrom-Json -ErrorAction Stop
        $executionResults += $jsonOutput
    }

    $allResults = $executionResults

    foreach ($result in $allResults) {
        $csvObject = [PSCustomObject]@{
            CheckItem = $result.CheckItem
            Category  = $result.Category
            Result    = $result.Result
            Details   = $result.Details
            Timestamp = $result.Timestamp
        }
        $processedResultsForCsv += $csvObject
        Write-Host "Result for $($result.CheckItem): $($result.Result)"
    }
} catch {
    Write-Warning "Error executing combined script: $($_.Exception.Message)"
}

Write-Host "`n--- All diagnostic checks completed on $ComputerName ---"

# --- Reports ---
$reportDir = Join-Path $PSScriptRoot "reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

$allResultsJson = $allResults | ConvertTo-Json -Depth 100

$reportFileName = "diagnostic_2026_report_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName).json"
$reportFilePath = Join-Path $reportDir $reportFileName
$allResultsJson | Set-Content $reportFilePath -Encoding UTF8
Write-Host "JSON report saved to: $reportFilePath"

$latestReportPath = Join-Path $reportDir "diagnostic_2026_report_latest_$($ComputerName).json"
$allResultsJson | Set-Content $latestReportPath -Encoding UTF8

if ($processedResultsForCsv) {
    $csvReportPath = Join-Path $reportDir "diagnostic_2026_report_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName).csv"
    $processedResultsForCsv | ConvertTo-Csv -NoTypeInformation | Set-Content $csvReportPath -Encoding UTF8
    Write-Host "CSV report saved to: $csvReportPath"

    $latestCsvPath = Join-Path $reportDir "diagnostic_2026_report_latest_$($ComputerName).csv"
    $processedResultsForCsv | ConvertTo-Csv -NoTypeInformation | Set-Content $latestCsvPath -Encoding UTF8
}

# --- Summary ---
$summary = @{
    Vulnerable             = 0
    Good                   = 0
    "Manual Check Required" = 0
    "Not Applicable"       = 0
    Error                  = 0
}

foreach ($r in $allResults) {
    if ($summary.ContainsKey($r.Result)) {
        $summary[$r.Result]++
    }
}

Write-Host "`n--- 2026 KICS Diagnostic Summary ---"
Write-Host "===================================="
Write-Host "Vulnerable                : $($summary.Vulnerable)"
Write-Host "Good                      : $($summary.Good)"
Write-Host "Manual Check Required     : $($summary.'Manual Check Required')"
Write-Host "Not Applicable            : $($summary.'Not Applicable')"
Write-Host "Error                     : $($summary.Error)"
Write-Host "------------------------------------"
Write-Host "Total Checks              : $($allResults.Count) / 64"
Write-Host "===================================="

$summaryObject = [PSCustomObject]@{
    Vulnerable          = $summary.Vulnerable
    Good                = $summary.Good
    ManualCheckRequired = $summary.'Manual Check Required'
    NotApplicable       = $summary.'Not Applicable'
    Error               = $summary.Error
    TotalChecks         = $allResults.Count
}

$summaryReportPath = Join-Path $reportDir "diagnostic_2026_summary_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName).csv"
$summaryObject | ConvertTo-Csv -NoTypeInformation | Set-Content $summaryReportPath -Encoding UTF8
Write-Host "Summary report saved to: $summaryReportPath"

Write-Host "Script finished at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Stop-Transcript

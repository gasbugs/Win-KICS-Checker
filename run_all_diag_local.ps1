# run_all_diag_local.ps1
# This script executes all diagnostic PowerShell scripts on the local machine and collects their results.

param(
    [string]$ChecksToRun = "all" # 실행할 점검 항목 (예: "1,3,10-15", "all")
)

$ErrorActionPreference = "Continue"

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ComputerName = $env:COMPUTERNAME

# --- Log setup ---
$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFileName = "diagnostic_log_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName)_local.log"
$logFilePath = Join-Path $logDir $logFileName
Start-Transcript -Path $logFilePath
# --- End Log setup ---

Write-Host "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Project Root: $PSScriptRoot"
Write-Host "Target Computer: $ComputerName (local)"

# Read common functions content once
$commonFunctionsPath = "$PSScriptRoot\scripts\common\common_functions.ps1"
if (Test-Path $commonFunctionsPath) {
    $commonFunctionsContent = Get-Content $commonFunctionsPath | Out-String
    Write-Host "Common functions loaded."
} else {
    Write-Warning "Common functions file not found: $commonFunctionsPath"
}

# List of all available diagnostic scripts
$allAvailableScripts = @(
    "scripts\01_AccountManagement\W-01_Administrator_Rename.ps1",
    "scripts\01_AccountManagement\W-02_Guest_Account_Disable.ps1",
    "scripts\01_AccountManagement\W-03_Unnecessary_Account_Removal.ps1",
    "scripts\01_AccountManagement\W-04_Account_Lockout_Threshold.ps1",
    "scripts\01_AccountManagement\W-05_Reversible_Encryption_Disable.ps1",
    "scripts\01_AccountManagement\W-06_Admin_Group_Min_Users.ps1",
    "scripts\01_AccountManagement\W-46_Disable_Everyone_Anonymous_Permissions.ps1",
    "scripts\01_AccountManagement\W-47_Account_Lockout_Duration_Setting.ps1",
    "scripts\01_AccountManagement\W-48_Password_Complexity_Setting.ps1",
    "scripts\01_AccountManagement\W-49_Minimum_Password_Length.ps1",
    "scripts\01_AccountManagement\W-50_Maximum_Password_Age.ps1",
    "scripts\01_AccountManagement\W-51_Minimum_Password_Age.ps1",
    "scripts\01_AccountManagement\W-52_Do_Not_Display_Last_User_Name.ps1",
    "scripts\01_AccountManagement\W-53_Allow_Local_Logon.ps1",
    "scripts\01_AccountManagement\W-54_Disable_Anonymous_SID_Name_Translation.ps1",
    "scripts\01_AccountManagement\W-55_Remember_Recent_Passwords.ps1",
    "scripts\01_AccountManagement\W-56_Restrict_Blank_Passwords_Console_Logon.ps1",
    "scripts\01_AccountManagement\W-57_Restrict_Remote_Terminal_User_Groups.ps1",
    "scripts\02_ServiceManagement\W-07_Share_Permission_Setting.ps1",
    "scripts\02_ServiceManagement\W-08_Harddisk_Default_Share_Removal.ps1",
    "scripts\02_ServiceManagement\W-09_Unnecessary_Service_Removal.ps1",
    "scripts\02_ServiceManagement\W-10_IIS_Service_Operation_Check.ps1",
    "scripts\02_ServiceManagement\W-11_Directory_Listing_Removal.ps1",
    "scripts\02_ServiceManagement\W-12_IIS_CGI_Execution_Restriction.ps1",
    "scripts\02_ServiceManagement\W-13_IIS_Parent_Path_Access_Prohibition.ps1",
    "scripts\02_ServiceManagement\W-14_IIS_Unnecessary_File_Removal.ps1",
    "scripts\02_ServiceManagement\W-15_Web_Process_Privilege_Restriction.ps1",
    "scripts\02_ServiceManagement\W-16_IIS_Link_Prohibition.ps1",
    "scripts\02_ServiceManagement\W-17_IIS_File_Upload_Download_Restriction.ps1",
    "scripts\02_ServiceManagement\W-18_IIS_DB_Connection_Vulnerability_Check.ps1",
    "scripts\02_ServiceManagement\W-19_IIS_Virtual_Directory_Deletion.ps1",
    "scripts\02_ServiceManagement\W-20_IIS_Data_File_ACL_Application.ps1",
    "scripts\02_ServiceManagement\W-21_IIS_Unused_Script_Mapping_Removal.ps1",
    "scripts\02_ServiceManagement\W-22_IIS_Exec_Command_Shell_Call_Diagnosis.ps1",
    "scripts\02_ServiceManagement\W-23_IIS_WebDAV_Deactivation.ps1",
    "scripts\02_ServiceManagement\W-24_NetBIOS_Binding_Service_Operation_Check.ps1",
    "scripts\02_ServiceManagement\W-25_FTP_Service_Operation_Check.ps1",
    "scripts\02_ServiceManagement\W-26_FTP_Directory_Access_Permission_Setting.ps1",
    "scripts\02_ServiceManagement\W-27_Anonymous_FTP_Prohibition.ps1",
    "scripts\02_ServiceManagement\W-28_FTP_Access_Control_Setting.ps1",
    "scripts\02_ServiceManagement\W-29_DNS_Zone_Transfer_Setting.ps1",
    "scripts\02_ServiceManagement\W-30_RDS_Removal.ps1",
    "scripts\02_ServiceManagement\W-31_Latest_Service_Pack_Application.ps1",
    "scripts\02_ServiceManagement\W-58_Terminal_Service_Encryption_Level.ps1",
    "scripts\02_ServiceManagement\W-59_Hide_IIS_Web_Service_Information.ps1",
    "scripts\02_ServiceManagement\W-60_SNMP_Service_Operation_Check.ps1",
    "scripts\02_ServiceManagement\W-61_SNMP_Community_String_Complexity.ps1",
    "scripts\02_ServiceManagement\W-62_SNMP_Access_Control_Setting.ps1",
    "scripts\02_ServiceManagement\W-63_DNS_Service_Operation_Check.ps1",
    "scripts\02_ServiceManagement\W-64_Block_HTTP_FTP_SMTP_Banners.ps1",
    "scripts\02_ServiceManagement\W-65_Telnet_Security_Setting.ps1",
    "scripts\02_ServiceManagement\W-66_Remove_Unnecessary_ODBC_OLEDB.ps1",
    "scripts\02_ServiceManagement\W-67_Remote_Terminal_Connection_Timeout.ps1",
    "scripts\02_ServiceManagement\W-68_Check_Suspicious_Scheduled_Tasks.ps1",
    "scripts\03_PatchManagement\W-32_Apply_Latest_Hot_Fix.ps1",
    "scripts\03_PatchManagement\W-33_Antivirus_Program_Update.ps1",
    "scripts\03_PatchManagement\W-69_System_Logging_Setting.ps1",
    "scripts\04_LogManagement\W-34_Regular_Log_Review_Reporting.ps1",
    "scripts\04_LogManagement\W-35_Remotely_Accessible_Registry_Paths.ps1",
    "scripts\04_LogManagement\W-70_Event_Log_Management_Settings.ps1",
    "scripts\04_LogManagement\W-71_Block_Remote_Event_Log_Access.ps1",
    "scripts\05_SecurityManagement\W-36_Antivirus_Program_Installation.ps1",
    "scripts\05_SecurityManagement\W-37_SAM_File_Access_Control.ps1",
    "scripts\05_SecurityManagement\W-38_Screensaver_Setting.ps1",
    "scripts\05_SecurityManagement\W-39_Disable_Shutdown_Without_Logon.ps1",
    "scripts\05_SecurityManagement\W-40_Force_Shutdown_Remote_System.ps1",
    "scripts\05_SecurityManagement\W-41_Disable_Immediate_Shutdown_Audit_Failure.ps1",
    "scripts\05_SecurityManagement\W-42_Disable_Anonymous_SAM_Enumeration.ps1",
    "scripts\05_SecurityManagement\W-43_Autologon_Feature_Control.ps1",
    "scripts\05_SecurityManagement\W-44_Allow_Removable_Media_Format_Eject.ps1",
    "scripts\05_SecurityManagement\W-45_Disk_Volume_Encryption_Setting.ps1",
    "scripts\05_SecurityManagement\W-72_DoS_Attack_Defense_Registry_Setting.ps1",
    "scripts\05_SecurityManagement\W-73_Prevent_Printer_Driver_Installation.ps1",
    "scripts\05_SecurityManagement\W-74_Idle_Time_Before_Session_Disconnect.ps1",
    "scripts\05_SecurityManagement\W-75_Warning_Message_Setting.ps1",
    "scripts\05_SecurityManagement\W-76_User_Home_Directory_Permissions.ps1",
    "scripts\05_SecurityManagement\W-77_LAN_Manager_Authentication_Level.ps1",
    "scripts\05_SecurityManagement\W-78_Secure_Channel_Data_Encryption_Signing.ps1",
    "scripts\05_SecurityManagement\W-79_File_Directory_Protection.ps1",
    "scripts\05_SecurityManagement\W-80_Computer_Account_Password_Max_Age.ps1",
    "scripts\05_SecurityManagement\W-81_Startup_Program_List_Analysis.ps1",
    "scripts\05_SecurityManagement\W-82_Use_Windows_Authentication_Mode.ps1"
)

$diagnosticScripts = @()

if ($ChecksToRun.ToLower() -eq "all") {
    Write-Host "Running all diagnostic checks."
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
        Write-Warning "No matching diagnostic scripts found for the specified checks. Exiting."
        Stop-Transcript | Out-Null
        return
    }
}

Write-Host "Scripts to be executed:"

$allResults = @()
$processedResultsForCsv = @()
$combinedScriptContent = $commonFunctionsContent
$combinedScriptContent += "`n`$WarningPreference = 'SilentlyContinue'`nImport-Module SmbShare -ErrorAction SilentlyContinue"

Write-Host "Starting selected diagnostic checks..."

foreach ($scriptPath in $allAvailableScripts) {
    if ($ChecksToRun.ToLower() -ne "all" -and $scriptPath -match "(W-\d+)") {
        $extractedPattern = $Matches[1]
        if ($diagnosticScripts -contains $extractedPattern) {
            Write-Host "Result: '$extractedPattern' is included in the allowed list. (OK)" -ForegroundColor Green
        } else {
            continue
        }
    }

    $fullScriptPath = Join-Path $PSScriptRoot $scriptPath
    if (Test-Path $fullScriptPath) {
        $combinedScriptContent += "`n" + (Get-Content $fullScriptPath -Raw) + "`n"
    } else {
        Write-Warning "Diagnostic script not found: $fullScriptPath"
    }
}

try {
    Write-Host "Executing combined script locally..."
    $executionResults = @()
    Invoke-Expression $combinedScriptContent | ForEach-Object {
        $jsonOutput = $_ | ConvertFrom-Json -ErrorAction Stop
        if ($jsonOutput -is [System.Array]) {
            $executionResults += $jsonOutput
        } else {
            $executionResults += $jsonOutput
        }
    }

    $allResults = $executionResults

    foreach ($result in $allResults) {
        $csvObject = [PSCustomObject]@{
            CheckItem = $result.CheckItem
            Category = $result.Category
            Result = $result.Result
            Details = $result.Details
            Timestamp = $result.Timestamp
        }

        if ($result.CheckItem -eq "W-03" -and $result.UserAccounts) {
            $userAccountDetails = $result.UserAccounts | ForEach-Object {
                "Name: $($_.Name), Enabled: $($_.Enabled), Description: $($_.Description)"
            }
            $csvObject.Details = "$($csvObject.Details) User Accounts: $($userAccountDetails -join '; ')"
        }

        if ($result.CheckItem -eq "W-06" -and $result.GroupMembers) {
            $groupMemberDetails = $result.GroupMembers | ForEach-Object {
                "Name: $($_.Name), ObjectClass: $($_.ObjectClass)"
            }
            $csvObject.Details = "$($csvObject.Details) Group Members: $($groupMemberDetails -join '; ')"
        }

        if ($result.CheckItem -eq "W-68" -and $result.ScheduledTasks) {
            $taskCount = $result.ScheduledTasks.Count
            $csvObject.Details = "Found $taskCount scheduled tasks. Detailed information is available in the JSON report."
            if ($result.Result -eq "Error") {
                $csvObject.Details = "Error checking scheduled tasks. Detailed error in JSON report."
            }
        }

        $processedResultsForCsv += $csvObject
        Write-Host "Result for $($result.CheckItem): $($result.Result)"
    }
} catch {
    Write-Warning "Error executing combined script locally: $($_.Exception.Message)"
    $errorResult = @{
        CheckItem = "CombinedScriptExecution"
        Category = "Error"
        Result = "Error"
        Details = "Combined script execution failed locally: $($_.Exception.Message)"
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $allResults += $errorResult
}

Write-Host "`n--- All diagnostic checks completed on $($ComputerName) ---"

$allResultsJson = $allResults | ConvertTo-Json -Depth 100
Write-Output $allResultsJson

$reportDir = Join-Path $PSScriptRoot "reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}
$reportFileName = "diagnostic_report_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName).json"
$reportFilePath = Join-Path $reportDir $reportFileName

$allResultsJson | Set-Content $reportFilePath -Encoding UTF8

Write-Host "`nFull report saved to: $($reportFilePath)"

$latestReportFileName = "diagnostic_report_latest_$($ComputerName).json"
$latestReportFilePath = Join-Path $reportDir $latestReportFileName
$allResultsJson | Set-Content $latestReportFilePath -Encoding UTF8
Write-Host "Latest JSON report saved to: $($latestReportFilePath)"

$csvReportFileName = "diagnostic_report_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName).csv"
$csvReportFilePath = Join-Path $reportDir $csvReportFileName

if ($processedResultsForCsv) {
    $processedResultsForCsv | ConvertTo-Csv -NoTypeInformation | Set-Content $csvReportFilePath -Encoding UTF8
    Write-Host "Full report saved to: $($csvReportFilePath)"

    $latestCsvReportFileName = "diagnostic_report_latest_$($ComputerName).csv"
    $latestCsvReportFilePath = Join-Path $reportDir $latestCsvReportFileName
    $processedResultsForCsv | ConvertTo-Csv -NoTypeInformation | Set-Content $latestCsvReportFilePath -Encoding UTF8
    Write-Host "Latest CSV report saved to: $($latestCsvReportFilePath)"
} else {
    Write-Warning "No results to convert to CSV. CSV file not generated."
}

$summary = @{
    Vulnerable = 0
    Good = 0
    "Manual Check Required" = 0
    "Not Applicable" = 0
    Error = 0
}

foreach ($r in $allResults) {
    if ($summary.ContainsKey($r.Result)) {
        $summary[$r.Result]++
    }
}

Write-Host "`n--- Diagnostic Summary ---"
Write-Host "========================="
Write-Host "Vulnerable                : $($summary.Vulnerable)"
Write-Host "Good                      : $($summary.Good)"
Write-Host "Manual Check Required     : $($summary.'Manual Check Required')"
Write-Host "Not Applicable            : $($summary.'Not Applicable')"
Write-Host "Error                     : $($summary.Error)"
Write-Host "--------------------------"
Write-Host "Total Checks              : $($allResults.Count)"
Write-Host "========================="

$summaryReportFileName = "diagnostic_summary_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($ComputerName).csv"
$summaryReportFilePath = Join-Path $reportDir $summaryReportFileName

$summaryObject = [PSCustomObject]@{
    Vulnerable = $summary.Vulnerable;
    Good = $summary.Good;
    ManualCheckRequired = $summary.'Manual Check Required';
    NotApplicable = $summary.'Not Applicable';
    Error = $summary.Error;
    TotalChecks = $allResults.Count
}

$summaryObject | ConvertTo-Csv -NoTypeInformation | Set-Content $summaryReportFilePath -Encoding UTF8
Write-Host "Summary report saved to: $($summaryReportFilePath)"

$latestSummaryReportFileName = "diagnostic_summary_latest_$($ComputerName).csv"
$latestSummaryReportFilePath = Join-Path $reportDir $latestSummaryReportFileName
$summaryObject | ConvertTo-Csv -NoTypeInformation | Set-Content $latestSummaryReportFilePath -Encoding UTF8
Write-Host "Latest Summary report saved to: $($latestSummaryReportFilePath)"

Write-Host "Script finished at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Stop-Transcript

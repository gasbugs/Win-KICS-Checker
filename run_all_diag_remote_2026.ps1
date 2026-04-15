# run_all_diag_remote_2026.ps1
# 2026 KICS Windows Server 취약점 진단 실행 스크립트 (원격)
# 원격 Windows 대상에 스크립트를 복사하고 PSRemoting으로 실행합니다.

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetComputer,
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,
    [string]$ChecksToRun = "all",
    [string]$RemoteWorkDir = "C:\kics2026_remote"
)

$ErrorActionPreference = "Continue"

$LocalRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

Write-Host "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Local Root  : $LocalRoot"
Write-Host "Target      : $TargetComputer"
Write-Host "Standard    : 2026 KICS (64 items)"

# --- Log setup (local) ---
$logDir = Join-Path $LocalRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFilePath = Join-Path $logDir "diagnostic_2026_log_${Timestamp}_${TargetComputer}_remote.log"
Start-Transcript -Path $logFilePath

# --- Test PSRemoting connectivity ---
Write-Host "Testing PSRemoting connectivity to $TargetComputer ..."
try {
    $session = New-PSSession -ComputerName $TargetComputer -Credential $Credential -ErrorAction Stop
    Write-Host "Connected to $TargetComputer."
} catch {
    Write-Error "Failed to connect to ${TargetComputer}: $_"
    Stop-Transcript
    return
}

# --- Create remote work directory ---
Invoke-Command -Session $session -ScriptBlock {
    param($dir)
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Write-Host "Remote work dir: $dir"
} -ArgumentList $RemoteWorkDir

# --- Copy scripts to remote ---
Write-Host "Copying scripts to $TargetComputer ..."
$scriptsSource = Join-Path $LocalRoot "scripts_2026"
Copy-Item -Path $scriptsSource -Destination $RemoteWorkDir -Recurse -ToSession $session -Force
Copy-Item -Path (Join-Path $LocalRoot "run_all_diag_local_2026.ps1") `
          -Destination $RemoteWorkDir -ToSession $session -Force
Write-Host "Copy complete."

# --- Execute remotely ---
Write-Host "Executing diagnostics on $TargetComputer ..."
$allResults = Invoke-Command -Session $session -ScriptBlock {
    param($workDir, $checks)
    Set-Location $workDir
    & "$workDir\run_all_diag_local_2026.ps1" -ChecksToRun $checks
} -ArgumentList $RemoteWorkDir, $ChecksToRun

# --- Download report ---
$reportDir = Join-Path $LocalRoot "reports"
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir | Out-Null }

$remoteReportPattern = Join-Path $RemoteWorkDir "reports\diagnostic_2026_report_latest_*.json"
$remoteReports = Invoke-Command -Session $session -ScriptBlock {
    param($pattern)
    Get-ChildItem $pattern -ErrorAction SilentlyContinue
} -ArgumentList $remoteReportPattern

if ($remoteReports) {
    $remoteReport = $remoteReports | Select-Object -First 1
    $localReportPath = Join-Path $reportDir "diagnostic_2026_report_${Timestamp}_${TargetComputer}_remote.json"
    Copy-Item -Path $remoteReport.FullName -Destination $localReportPath -FromSession $session
    Write-Host "Report saved to: $localReportPath"

    # Also save as latest
    $latestPath = Join-Path $reportDir "diagnostic_2026_report_latest_${TargetComputer}_remote.json"
    Copy-Item -Path $localReportPath -Destination $latestPath -Force
}

# --- Cleanup remote ---
Invoke-Command -Session $session -ScriptBlock {
    param($dir)
    Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Remote work dir cleaned up."
} -ArgumentList $RemoteWorkDir

Remove-PSSession $session

# --- Summary ---
if ($allResults) {
    $summary = @{ Vulnerable = 0; Good = 0; 'Manual Check Required' = 0; 'Not Applicable' = 0; Error = 0 }
    foreach ($r in $allResults) {
        if ($summary.ContainsKey($r.Result)) { $summary[$r.Result]++ }
    }
    Write-Host "`n--- 2026 KICS Diagnostic Summary ($TargetComputer) ---"
    Write-Host "===================================================="
    Write-Host "Vulnerable                : $($summary.Vulnerable)"
    Write-Host "Good                      : $($summary.Good)"
    Write-Host "Manual Check Required     : $($summary.'Manual Check Required')"
    Write-Host "Not Applicable            : $($summary.'Not Applicable')"
    Write-Host "Error                     : $($summary.Error)"
    Write-Host "----------------------------------------------------"
    Write-Host "Total Checks              : $($allResults.Count) / 64"
    Write-Host "===================================================="
}

Write-Host "Script finished at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Stop-Transcript

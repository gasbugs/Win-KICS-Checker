# setup_services_2026.ps1
# W-22/23/24(FTP), W-25/32(DNS), W-30/31(SNMP), W-33(배너) 진단 환경 구성
# 취약한 기본 설정으로 구성하여 각 점검이 실제로 동작하도록 함.
# Exit codes: 0=완료, 1001=재시작 필요

$ErrorActionPreference = "Stop"

function Write-Step { param([string]$msg) Write-Host "[SETUP] $msg" }

# ── 1. Windows Feature 설치 ────────────────────────────────────────
Write-Step "Installing Windows features: IIS+FTP, DNS, SNMP..."
$result = Install-WindowsFeature Web-Server, Web-Ftp-Service, DNS, SNMP-Service `
    -IncludeManagementTools

if ($result.RestartNeeded -ne 'No') {
    Write-Step "Restart required after feature install. Rebooting..."
    exit 1001
}
Write-Step "Features installed (no restart needed)."

# ── 2. FTP 서비스 구성 (W-22/23/24/33) ────────────────────────────
Write-Step "Configuring IIS FTP site..."

# IIS WebAdministration 모듈 로드
Import-Module WebAdministration -ErrorAction SilentlyContinue

# FTP 루트 디렉터리 생성
$ftpRoot = "C:\inetpub\ftproot"
if (-not (Test-Path $ftpRoot)) {
    New-Item -ItemType Directory -Path $ftpRoot -Force | Out-Null
}

# W-22: Everyone에 쓰기 권한 부여 (취약 설정)
$acl = Get-Acl $ftpRoot
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Everyone", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl -Path $ftpRoot -AclObject $acl
Write-Step "W-22: Everyone=Modify permission set on $ftpRoot"

# 기존 Default Web Site가 있으면 FTP 바인딩 추가, 없으면 새 FTP 사이트 생성
$ftpSiteName = "TestFTP"
$existingFtp = Get-Website -Name $ftpSiteName -ErrorAction SilentlyContinue
if (-not $existingFtp) {
    New-WebFtpSite -Name $ftpSiteName -PhysicalPath $ftpRoot -Port 21 -Force
    Write-Step "FTP site '$ftpSiteName' created."
} else {
    Write-Step "FTP site '$ftpSiteName' already exists."
}

# W-23: 익명 FTP 인증 활성화 (취약 설정)
Set-WebConfigurationProperty `
    -Filter "/system.ftpServer/security/authentication/anonymousAuthentication" `
    -PSPath "IIS:\Sites\$ftpSiteName" `
    -Name "enabled" -Value $true
Write-Step "W-23: Anonymous FTP authentication ENABLED (vulnerable)"

# W-24: IP 접근 제어 미설정 (allowUnlisted=true, 취약 설정)
# IIS FTP는 기본적으로 allowUnlisted=true 이므로 추가 설정 불필요
# 명시적으로 설정
try {
    Set-WebConfigurationProperty `
        -Filter "/system.ftpServer/security/ipSecurity" `
        -PSPath "IIS:\Sites\$ftpSiteName" `
        -Name "allowUnlisted" -Value $true
    Write-Step "W-24: IP security allowUnlisted=true (vulnerable)"
} catch {
    Write-Step "W-24: Could not set allowUnlisted (may be default): $_"
}

# FTP 서비스 시작
Start-Service FTPSVC -ErrorAction SilentlyContinue
Write-Step "FTPSVC started."

# ── 3. DNS 서비스 구성 (W-25/32) ──────────────────────────────────
Write-Step "Configuring DNS Server..."
Start-Service DNS -ErrorAction SilentlyContinue

# W-32: 기본 존 생성 후 동적 업데이트=Nonsecure (취약 설정)
$zoneName = "test.local"
$existingZone = Get-DnsServerZone -Name $zoneName -ErrorAction SilentlyContinue
if (-not $existingZone) {
    Add-DnsServerPrimaryZone -Name $zoneName -ZoneFile "$zoneName.dns" -DynamicUpdate NonsecureAndSecure
    Write-Step "W-32: DNS zone '$zoneName' created with DynamicUpdate=NonsecureAndSecure (vulnerable)"
} else {
    Set-DnsServerPrimaryZone -Name $zoneName -DynamicUpdate NonsecureAndSecure
    Write-Step "W-32: DNS zone '$zoneName' already exists, set DynamicUpdate=NonsecureAndSecure"
}

# W-25: 존 전송을 모든 서버로 허용 (취약 설정)
Set-DnsServerPrimaryZone -Name $zoneName -SecureSecondaries TransferToAnyServer
Write-Step "W-25: Zone transfer set to TransferToAnyServer (vulnerable)"

# ── 4. SNMP 서비스 구성 (W-30/31) ─────────────────────────────────
Write-Step "Configuring SNMP Service..."
Start-Service SNMP -ErrorAction SilentlyContinue

# W-30: 커뮤니티 스트링 "public" 설정 (취약 설정)
$snmpCommunityPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
if (-not (Test-Path $snmpCommunityPath)) {
    New-Item -Path $snmpCommunityPath -Force | Out-Null
}
# 기존 커뮤니티 삭제 후 재설정
Remove-ItemProperty -Path $snmpCommunityPath -Name * -ErrorAction SilentlyContinue
New-ItemProperty -Path $snmpCommunityPath -Name "public" -Value 4 -PropertyType DWord -Force | Out-Null
Write-Step "W-30: SNMP community string 'public' (value=4 READ_ONLY) set (vulnerable)"

# W-31: PermittedManagers 비워두기 (모든 호스트 허용, 취약 설정)
$snmpMgrPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"
if (Test-Path $snmpMgrPath) {
    Remove-ItemProperty -Path $snmpMgrPath -Name * -ErrorAction SilentlyContinue
    Write-Step "W-31: PermittedManagers cleared (vulnerable — all hosts allowed)"
} else {
    New-Item -Path $snmpMgrPath -Force | Out-Null
    Write-Step "W-31: PermittedManagers key created empty (vulnerable)"
}

# ── 5. 최종 서비스 상태 확인 ─────────────────────────────────────
Write-Step "Verifying service states..."
@("FTPSVC", "DNS", "SNMP") | ForEach-Object {
    $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Step "  $_ : $($svc.Status)"
    } else {
        Write-Step "  $_ : NOT FOUND"
    }
}

Write-Step "Service setup complete."
exit 0

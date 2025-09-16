# 주요 정보통신기반시설 Windows 취약점 진단 스크립트

## 1. 프로젝트 개요
이 저장소는 KISA가 배포한 "주요 정보통신기반시설 기술적 취약점 분석·평가 방법 상세 가이드"를 토대로 Windows Server 2019 환경의 보안 항목을 자동 점검하는 PowerShell 스크립트를 제공합니다. 모든 진단 스크립트는 JSON 형식의 결과를 반환하며, 통합 실행 스크립트가 보고서를 생성해 관리자에게 손쉽게 현재 상태를 전달합니다. 가이드 원문에서 Windows 관련 내용만 발췌한 자료는 `docs/`에 포함되어 있습니다.

## 2. 디렉터리 구조
```plaintext
Win-KICS-Checker/
├── CHANGELOG.md
├── run_all_diag_local.ps1
├── run_all_diag_remote.ps1
├── docs/
│   └── ... (원본 가이드 및 참조 문서)
├── logs/
│   └── diagnostic_log_*.log (원격 실행 기록)
├── reports/
│   ├── diagnostic_report_*.json / *.csv
│   └── diagnostic_summary_*.csv (원격 실행 시)
├── scripts/
│   ├── 01_AccountManagement/
│   ├── 02_ServiceManagement/
│   ├── 03_PatchManagement/
│   ├── 04_LogManagement/
│   ├── 05_SecurityManagement/
│   └── common/common_functions.ps1
└── test_env/
    ├── Vagrantfile
    └── provisioning/
```

## 3. 사전 준비
- PowerShell 5.1 이상(또는 PowerShell 7)에서 테스트했습니다.
- 로컬 실행 전 현재 세션에 한해 실행 정책을 완화하세요.
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope Process
  ```
- 원격 점검은 WinRM HTTPS(기본 포트 5986)가 활성화된 Windows Server에서 동작합니다. 자체 서명 인증서를 사용하는 경우 `CHANGELOG.md`의 설정 가이드를 따라 구성하세요.

## 4. 실행 방법
### 4.1 로컬 전체 진단
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\run_all_diag_local.ps1
```
- 모든 점검 스크립트를 로컬에서 실행하고 JSON·CSV 보고서를 `reports/`에 저장합니다.

### 4.2 원격 전체 진단
```powershell
$pw = Read-Host -Prompt 'Password'
./run_all_diag_remote.ps1 -ComputerName <호스트명 또는 IP> -Port 5986 -Username <계정> -Password $pw
Remove-Variable pw
```
- HTTPS(UseSSL)로 원격 명령을 실행합니다.
- `-ComputerName`은 대상 서버 FQDN/IPv4/IPv6를 허용하며, 미지정 시 현재 컴퓨터 이름을 사용합니다.
- `-Port`는 기본 5986이며 필요 시 변경 가능합니다.
- `-Username`과 `-Password`를 지정하면 PSCredential이 생성됩니다. 암호는 평문 문자열이어야 하므로 입력 후 꼭 변수에서 제거하세요.
- 실행 기록은 `logs/diagnostic_log_YYYYMMDD_HHmmss_<ComputerName>.log`에 남고, 암호 문자열은 마스킹됩니다.

### 4.3 선택 실행 (-ChecksToRun)
- 기본값 `all`은 전체 항목을 수행합니다.
- `-ChecksToRun`에 콤마·범위 형태로 번호를 전달하여 특정 항목만 실행할 수 있습니다.
  ```powershell
  ./run_all_diag_remote.ps1 -ComputerName 192.0.2.10 -Username admin -Password $pw -ChecksToRun '1,3,10-15'
  ./run_all_diag_local.ps1  # 로컬 스크립트는 전체 항목만 지원
  ```
- 번호는 스크립트 파일의 접두어 `W-XX`와 동일하며, 존재하지 않는 번호는 무시됩니다.

## 5. 보고서와 로그 확인
- `diagnostic_report_YYYYMMDD_HHmmss_<ComputerName>.json` : 모든 항목의 원본 결과.
- `diagnostic_report_YYYYMMDD_HHmmss_<ComputerName>.csv` : 요약 형태로 변환한 표 데이터.
- `diagnostic_report_latest_<ComputerName>.json/csv` : 원격 실행 시 최신 결과를 덮어씁니다.
- `diagnostic_summary_*.csv` : 원격 실행이 완료되면 취약(Vulnerable), 양호(Good), 수동 점검 등 결과 카운트를 제공합니다.
- 스크립트 오류나 예외 발생 시 메시지는 콘솔과 로그에 동시에 남습니다.

## 6. 스크립트 작성 및 테스트 팁
- 모든 새 진단 스크립트는 `W-XX_Description.ps1` 형식을 따르고, `ConvertTo-Json -Compress`로 결과를 출력해야 합니다.
- 공통 함수는 `scripts/common/common_functions.ps1`에 정의해 두고 다른 스크립트에서 재사용하세요.
- 테스트는 Windows Server 2019(또는 동등한 테스트 VM)에서 진행하고, 보고서가 정상 생성되었는지 확인합니다.

## 7. 라이선스 및 참고 자료
- 라이선스 정보는 `license.md`를 확인하세요.
- 점검 항목 상세 설명은 `docs/Windows_Vulnerability_Guide.txt`에서 확인할 수 있습니다.
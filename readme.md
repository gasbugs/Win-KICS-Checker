# 주요 정보 통신 기반 시설 Windows 취약점 진단 스크립트

## 1. 프로젝트 개요

본 프로젝트는 KISA(한국인터넷진흥원)에서 배포한 "주요 정보 통신 기반 시설 기술적 취약점 분석·평가 방법 상세 가이드"를 기반으로, Windows 서버의 보안 취약점을 자동 진단하는 PowerShell 스크립트 모음입니다. **본 스크립트는 Windows Server 2019 환경에 최적화되어 개발 및 테스트되었습니다.** 프로젝트에서 사용하는 가이드는 `docs/` 폴더에 위치해 있으며, 원본 가이드에서 Windows 관련 내용만 발췌한 버전입니다. 각 스크립트는 특정 보안 항목을 점검하고 결과를 보고서로 생성하여 관리자가 시스템의 보안 상태를 쉽고 빠르게 파악할 수 있도록 돕는 것을 목표로 합니다.

## 2. 프로젝트 구조
Win-KICS-Checker/
├── .gitignore
├── CHANGELOG.md
├── HISTORY.md
├── license.md
├── PLAN.md
├── readme.md
├── run_all_diag_local.ps1
├── run_all_diag_remote.ps1
├── docs/
│   └── ... (취약점 가이드 문서)
├── logs/
├── reports/
│   └── ... (진단 보고서)
├── scripts/
│   ├── 01_AccountManagement/
│   ├── 02_ServiceManagement/
│   ├── 03_PatchManagement/
│   ├── 04_LogManagement/
│   ├── 05_SecurityManagement/
│   └── common/
│       └── common_functions.ps1
└── test_env/
    └── ... (테스트 환경 설정 파일)

## 사용법

### 1. 스크립트 실행

진단 스크립트는 `run_all_diag_local.ps1` (로컬 시스템 진단)과 `run_all_diag_remote.ps1` (원격 시스템 진단) 두 가지가 있습니다.

#### 전체 진단 실행 (로컬)

```powershell
.un_all_diag_local.ps1
```

#### 전체 진단 실행 (원격)

```powershell
.un_all_diag_remote.ps1 -ComputerName <원격_컴퓨터_이름_또는_IP> -Credential (Get-Credential)
```
또는 기본값 사용:

```powershell
.un_all_diag_remote.ps1
```
(기본값: ComputerName=127.0.0.1, Username=vagrant, Password=vagrant)

#### 특정 진단 항목만 실행
원하는 진단 스크립트 파일명(예: `W-01_Administrator_Rename.ps1`)을 리스트로 전달하여 특정 항목만 진단할 수 있습니다.

```powershell
.un_all_diag_local.ps1 -CheckList "W-01_Administrator_Rename.ps1", "W-02_Guest_Account_Disable.ps1"
```
또는 원격으로:

```powershell
.un_all_diag_remote.ps1 -ComputerName <원격_컴퓨터_이름_또는_IP> -Credential (Get-Credential) -CheckList "W-01_Administrator_Rename.ps1", "W-02_Guest_Account_Disable.ps1"
```

### 2. 보고서 확인
점검 완료 후 `reports/` 디렉토리에서 생성된 보고서 파일을 확인합니다.


프로젝트는 다음과 같은 구조로 구성되어 있습니다.

```
.
├── docs/
│   └── Windows_Vulnerability_Guide.txt
│
├── scripts/
│   ├── 01_AccountManagement/
│   │   ├── W-01_Administrator_Rename.ps1
│   │   └── ... (W-02 to W-06)
│   │
│   ├── 02_ServiceManagement/
│   │   ├── W-07_Share_Permission_Setting.ps1
│   │   └── ... (W-08 to W-20)
│   │
│   ├── 03_PatchManagement/
│   │   └── W-40_Latest_Security_Patch_Application.ps1
│   │
│   ├── 04_LogManagement/
│   │   └── W-60_Log_Policy_Setting.ps1
│   │
│   └── common/
│       └── common_functions.ps1
│
├── reports/
│   └── (진단 결과 보고서가 저장될 디렉터리)
│
├── test_env/
│   ├── Vagrantfile
│   └── provisioning/
│       └── install_applications.ps1
│
├── run_all_diagnostics.ps1
└── readme.md
```

- **docs/**: 관련 문서 및 가이드라인을 저장하는 디렉터리입니다. (`Windows_Vulnerability_Guide.txt` 포함)
- **scripts/**: 실제 진단 스크립트가 위치하는 디렉터리입니다. 가이드라인의 분류에 따라 하위 디렉터리로 구분됩니다.
  - **01_AccountManagement/**, **02_ServiceManagement/** 등: 각 보안 점검 항목 분류에 따른 스크립트가 포함됩니다. (모든 파일명 영문으로 변경됨)
  - **common/**: 스크립트 전반에서 사용되는 공통 함수나 변수를 정의합니다.
- **reports/**: 진단 스크립트 실행 후 결과 보고서가 생성되는 디렉터리입니다.
- **run_all_diagnostics.ps1**: `scripts` 폴더 내의 모든 진단 스크립트를 순차적으로 실행하는 메인 스크립트입니다.

## 3. 사용 방법

### 사전 준비

PowerShell 스크립트 실행을 위해 실행 정책을 변경해야 할 수 있습니다.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
```

### 전체 진단 실행

**원격 컴퓨터에서 실행 (권장):**
WinRM이 구성된 원격 컴퓨터에서 진단을 실행하려면 다음 명령을 사용합니다.

```powershell
powershell.exe -File ".\run_all_diagnostics.ps1" -ComputerName "127.0.0.1" -Port 5986 -Username "vagrant" -Password "vagrant"
```
(또는 `127.0.0.1` 대신 실제 원격 컴퓨터의 이름이나 IP 주소를, `vagrant` 대신 실제 사용자 이름과 비밀번호를 사용합니다.)

**로컬 컴퓨터에서 실행:**
별도의 원격 설정 없이 현재 사용 중인 로컬 컴퓨터에서 진단을 실행하려면 다음 명령을 사용합니다.

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\run_all_diag_local.ps1"
```

진단 결과는 콘솔에 출력되며, `reports` 폴더에 `diagnostic_report_YYYYMMDD_HHmmss_ComputerName.json` 형식의 JSON 보고서 파일과 `diagnostic_report_YYYYMMDD_HHmmss_ComputerName.csv` 형식의 CSV 보고서 파일로 저장됩니다.

**참고:** WinRM 구성 및 HTTPS 연결에 대한 자세한 내용은 `CHANGELOG.md` 파일을 참조하십시오.


### 개별 진단 실행

특정 항목만 진단하고 싶을 경우, `scripts` 폴더 내의 원하는 스크립트를 직접 실행할 수 있습니다. (예: `scripts\01_AccountManagement\W-01_Administrator_Rename.ps1`)

```powershell
powershell.exe -File .\scripts\01_AccountManagement\W-01_Administrator_Rename.ps1
```

## 4. 진단 항목

본 스크립트는 다음의 주요 항목들을 진단합니다.

- **계정 관리 (18개 항목):** W-01 ~ W-06, W-46 ~ W-57
- **서비스 관리 (28개 항목):** W-07 ~ W-31, W-58 ~ W-68
- **패치 관리 (3개 항목):** W-32, W-33, W-69
  *참고: W-32, W-33, W-34 항목은 스크립트의 설계상 항상 '수동 확인 필요'로 보고됩니다.*
- **로그 관리 (4개 항목):** W-34, W-35, W-70, W-71
- **보안 관리 (21개 항목):** W-36 ~ W-45, W-72 ~ W-82

(각 항목의 세부 내용은 `docs/Windows_Vulnerability_Guide.txt` 파일에서 확인하실 수 있습니다.)

## 5. 기여 방법

- 버그 리포트나 기능 제안은 언제나 환영합니다.
- 스크립트 개선에 참여하고 싶으시면 Pull Request를 생성해주세요.
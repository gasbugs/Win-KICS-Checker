# Repository Guidelines

## 프로젝트 구조 및 모듈
핵심 진단 스크립트는 가이드 장별로 정리된 `scripts/`에 배치합니다(예: `01_AccountManagement`, `05_SecurityManagement`). 공용 함수는 `scripts/common/`에 보관하고, 실행 결과 보고서는 `reports/`에 저장됩니다. 점검 중 수집한 로그는 `logs/`, 참고 문서와 번역본은 `docs/`, 실험용 Vagrant 환경은 `test_env/`에 둡니다. 새 자산을 추가할 때도 이 구조를 유지해 운영자가 쉽게 찾을 수 있도록 하세요.

## 빌드·테스트·개발 명령
PowerShell 5.1 이상 혹은 pwsh를 사용하세요. 필요 시 셸 범위에서 실행 정책을 `Set-ExecutionPolicy RemoteSigned -Scope Process`로 설정합니다. 전체 로컬 진단은 `./run_all_diag_local.ps1`, 원격 점검은 `./run_all_diag_remote.ps1 -ComputerName <host> -Credential (Get-Credential)`을 실행합니다. Windows Server 테스트 박스가 필요하면 `test_env/`에서 `vagrant up`을 실행한 뒤 기본 `vagrant` 자격 증명으로 `127.0.0.1`에 연결하세요. 산출물이 갱신되면 동일 스크립트를 재실행해 보고서를 재생성하고, 불필요한 파일은 직접 정리합니다.

## 코딩 스타일 및 명명 규칙
새 점검 항목은 KISA 순서를 유지하며 `W-XX_Description.ps1` 형식으로 작성합니다. 들여쓰기는 4칸, 문자열은 이중 따옴표, 비교 연산은 명시적으로 사용하세요. 함수는 PascalCase, 변수는 camelCase, 상수는 ALL_CAPS로 표기합니다. 공통 로직은 `scripts/common/common_functions.ps1`에서 재사용하고, 외부 호출은 `try { ... } catch { ... }`로 감싸며 결과는 `ConvertTo-Json -Compress`로 반환합니다. 주석은 반드시 필요한 검증 로직에만 추가합니다.

## 테스트 지침
모든 스크립트는 Windows Server 2019에서 오류 없이 동작해야 합니다. Vagrant 상자나 격리된 VM에서 검증하고, 가능하다면 “Good”과 “Vulnerable” 경로 모두 재현하세요. 시스템 상태를 변경해야 한다면 단계와 복구 방법을 함께 기록합니다. 실행 후 `reports/`에 JSON·CSV 보고서가 생성되고 불필요한 산출물이 남지 않았는지 확인하며, 이상 징후는 `logs/`에 남겨 후속 분석에 대비합니다.

## 커밋 및 PR 가이드라인
기록된 히스토리를 따르면서 간결한 명령형 제목을 사용하세요(예: `Update report parser`, `로그 수집 개선`). 메시지 안에서는 영어 또는 한국어 중 하나만 사용하고, 제목은 50자 내로 유지합니다. 본문에는 변경 이유나 참고 자료를 남기세요. PR을 올릴 때는 시나리오 요약, 수정한 주요 스크립트 목록, 샘플 보고서나 콘솔 출력, 관련 이슈 링크, 그리고 수행한 수동 테스트 명령을 포함합니다.

## 보안 및 구성 팁
스크립트와 문서에 자격 증명을 직접 기록하지 말고 항상 `Get-Credential` 프롬프트를 사용하세요. 원격 점검 시에는 `CHANGELOG.md`에 정리된 WinRM HTTPS 설정을 준수하고, 점검 후 임시 계정을 제거합니다. 고객 데이터가 보고서에 포함될 가능성이 있다면 저장 전 반드시 마스킹하거나 회수 계획을 마련하세요.

#!/bin/bash
# init.sh — Win-KICS-Checker 2026 하네스 초기화 스크립트
set -euo pipefail

echo "=== Win-KICS-Checker 2026 Migration Harness ==="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# 1. 프로젝트 디렉터리 확인
if [ ! -f "feature-list.json" ]; then
    echo "ERROR: feature-list.json not found. Are you in the project root?"
    exit 1
fi

# 2. 필수 디렉터리 확인
for dir in scripts_2026/01_AccountManagement scripts_2026/02_ServiceManagement scripts_2026/03_PatchManagement scripts_2026/04_LogManagement scripts_2026/05_SecurityManagement scripts_2026/common tests/e2e; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# 3. Git 상태 출력
echo ""
echo "--- Git Status ---"
git branch --show-current
git log --oneline -5
echo ""

# 4. 2026 스크립트 진행 상황
total_expected=64
total_created=$(find scripts_2026 -name "W-*.ps1" 2>/dev/null | wc -l | tr -d ' ')
echo "--- 2026 Scripts Progress ---"
echo "Expected: $total_expected"
echo "Created:  $total_created"
echo "Remaining: $((total_expected - total_created))"
echo ""

# 5. 스모크 테스트: feature-list.json 유효성
if command -v python3 &>/dev/null; then
    python3 -c "import json; json.load(open('feature-list.json'))" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "SMOKE: feature-list.json is valid JSON ✓"
    else
        echo "SMOKE: feature-list.json is INVALID JSON ✗"
        exit 1
    fi
else
    echo "SMOKE: python3 not available, skipping JSON validation"
fi

echo ""
echo "=== init.sh completed successfully ==="

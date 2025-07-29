#!/bin/bash

# SOCAR B2B 보안 스캔 실행 스크립트
# 사용법: ./run-security-scan.sh [도메인명]

set -e

echo "🛡️ SOCAR B2B 보안 스캔 시작..."
echo "================================="

# 결과 디렉토리 생성
mkdir -p .sarif

# 도메인별 스캔 또는 전체 스캔
if [ $# -eq 1 ]; then
    DOMAIN=$1
    echo "📦 도메인별 스캔: $DOMAIN"
    
    # Apex 클래스 스캔
    if [ -d "force-app/main/default/classes/${DOMAIN}_domain" ]; then
        echo "🔍 ${DOMAIN} 도메인 Apex 스캔 중..."
        sfdx scanner:run \
            --target "force-app/main/default/classes/${DOMAIN}_domain" \
            --format sarif \
            --outfile ".sarif/${DOMAIN}-apex-scan.sarif" \
            --severity-threshold 2 \
            --pmdconfig "security-config/pmd-ruleset.xml"
    fi
    
    # LWC 컴포넌트 스캔
    if [ -d "force-app/main/default/lwc" ]; then
        echo "⚡ ${DOMAIN} LWC 스캔 중..."
        eslint "force-app/main/default/lwc" \
            --config "security-config/.eslintrc-security.json" \
            --format @microsoft/eslint-formatter-sarif \
            --output-file ".sarif/${DOMAIN}-lwc-scan.sarif" || true
    fi
else
    echo "🌍 전체 프로젝트 스캔"
    
    # 전체 Apex 스캔
    echo "🔍 전체 Apex 코드 스캔 중..."
    sfdx scanner:run \
        --target "force-app/main/default/classes,force-app/main/default/triggers" \
        --format sarif \
        --outfile ".sarif/full-apex-scan.sarif" \
        --severity-threshold 2 \
        --pmdconfig "security-config/pmd-ruleset.xml"
    
    # 전체 LWC 스캔  
    echo "⚡ 전체 LWC 스캔 중..."
    eslint "force-app/main/default/lwc" \
        --config "security-config/.eslintrc-security.json" \
        --format @microsoft/eslint-formatter-sarif \
        --output-file ".sarif/full-lwc-scan.sarif" || true
        
    # Visualforce 페이지 스캔
    echo "📄 Visualforce 페이지 스캔 중..."
    sfdx scanner:run \
        --target "force-app/main/default/pages" \
        --format sarif \
        --outfile ".sarif/visualforce-scan.sarif" \
        --severity-threshold 3 || true
fi

echo ""
echo "✅ 보안 스캔 완료!"
echo "📊 결과 파일 위치: .sarif/ 디렉토리"
echo ""

# 결과 요약
echo "📈 스캔 결과 요약:"
echo "=================="
for sarif_file in .sarif/*.sarif; do
    if [ -f "$sarif_file" ]; then
        filename=$(basename "$sarif_file")
        issue_count=$(jq '.runs[0].results | length' "$sarif_file" 2>/dev/null || echo "0")
        echo "📋 $filename: $issue_count 개 이슈 발견"
    fi
done

echo ""
echo "🔗 GitHub에서 SARIF 결과를 확인하려면:"
echo "   Repository → Security → Code scanning alerts"
echo ""
echo "🚀 다음 단계:"
echo "   1. .sarif/ 디렉토리의 결과 파일 검토"
echo "   2. 발견된 보안 이슈 해결"
echo "   3. GitHub Actions로 자동화 설정"

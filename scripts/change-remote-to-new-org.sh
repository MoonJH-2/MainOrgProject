#!/bin/bash

# 새 GitHub Organization으로 원격 저장소 변경 스크립트
# 사용법: ./change-remote-to-new-org.sh [새-organization-이름]

set -e

NEW_ORG_NAME=${1:-"SOCAR-B2B-Innovation-Team"}
REPO_NAME="MainOrgProject"

echo "🔄 새 Organization으로 원격 저장소 변경 중..."
echo "================================="
echo "새 Organization: $NEW_ORG_NAME"
echo "저장소 이름: $REPO_NAME"
echo "================================="

# 현재 원격 저장소 확인
echo "📍 현재 원격 저장소:"
git remote -v

# 새 원격 저장소 URL 설정
NEW_REMOTE_URL="git@github.com:${NEW_ORG_NAME}/${REPO_NAME}.git"
echo ""
echo "🎯 새 원격 저장소 URL: $NEW_REMOTE_URL"

# 원격 저장소 URL 변경
git remote set-url origin $NEW_REMOTE_URL

# 변경 결과 확인
echo ""
echo "✅ 원격 저장소 변경 완료:"
git remote -v

echo ""
echo "🚀 이제 다음 명령어로 새 Organization에 푸시하세요:"
echo "   git push -u origin main"

# 🛡️ SOCAR B2B 브랜치 보호 규칙 가이드

## 📋 보호된 브랜치
- `main` - 운영 환경 (완전 보호)
- `develop` - 개발 통합 (부분 보호)

## 🔄 개발 워크플로우

### 1. 새 기능 개발
```bash
# 1. 최신 main 브랜치로 시작
git checkout main
git pull origin main

# 2. 기능 브랜치 생성
git checkout -b feature/payment-integration

# 3. 개발 및 커밋
git add .
git commit -m "feat: 결제 연동 기능 추가"

# 4. 브랜치 푸시
git push origin feature/payment-integration
```

### 2. Pull Request 생성
```markdown
제목: feat: 결제 연동 기능 추가

설명:
- 토스페이먼츠 API 연동
- 결제 상태 실시간 업데이트
- 단위 테스트 추가

체크리스트:
- [x] 코드 리뷰 완료
- [x] 단위 테스트 통과
- [x] 보안 스캔 통과
- [x] Salesforce 배포 검증 완료
- [x] 문서 업데이트
```

### 3. 필수 검증 과정

#### 🔒 보안 검증
```bash
# 로컬에서 보안 스캔 실행
./scripts/run-security-scan.sh

# 결과 확인
✅ No security vulnerabilities found
✅ PMD rules passed
✅ SARIF scan completed
```

#### 🚀 Salesforce 검증
```bash
# 배포 전 검증
sfdx force:source:deploy -p force-app/main/default --checkonly

# 결과 확인
✅ Deploy validation successful
✅ All Apex tests passed
✅ Code coverage: 85%
```

#### 🧪 테스트 검증
```bash
# 단위 테스트 실행
npm test

# 결과 확인
✅ All tests passed (24/24)
✅ Code coverage: 92%
```

## ⚠️ 주의사항

### 금지된 작업
❌ `main` 브랜치에 직접 푸시
❌ 강제 푸시 (force push)
❌ 브랜치 삭제
❌ 리뷰 없는 병합

### 허용된 작업
✅ Feature 브랜치에서 개발
✅ Pull Request를 통한 병합
✅ 코드 리뷰 및 승인
✅ 자동화된 검증 통과

## 🚨 긴급 상황 대응

### 핫픽스 프로세스
```bash
# 1. 핫픽스 브랜치 생성
git checkout main
git checkout -b hotfix/critical-payment-bug

# 2. 빠른 수정
git add .
git commit -m "fix: 결제 연동 크리티컬 버그 수정"

# 3. 긴급 PR 생성 (빠른 리뷰 요청)
git push origin hotfix/critical-payment-bug
```

### 규칙 우회 (조직 Owner만 가능)
```
상황: 심각한 보안 이슈 또는 시스템 다운
절차:
1. 조직 Owner가 일시적으로 보호 규칙 비활성화
2. 긴급 수정 사항 적용
3. 즉시 보호 규칙 재활성화
4. 사후 검토 및 문서화
```

## 📊 규칙 준수 현황

### 대시보드 메트릭스
- ✅ PR 리뷰율: 100%
- ✅ 자동 테스트 통과율: 98%
- ✅ 보안 스캔 통과율: 100%
- ✅ 배포 검증 성공률: 95%

### 위반 시 조치
1. **1차 위반**: 경고 및 가이드 안내
2. **2차 위반**: 추가 교육 및 권한 검토
3. **3차 위반**: 권한 제한 및 팀 리더 상담

## 🎯 지속적 개선

### 월간 검토 항목
- [ ] 보호 규칙 효용성 검토
- [ ] 개발 프로세스 개선점 도출
- [ ] 팀원 피드백 수집
- [ ] 새로운 보안 요구사항 반영

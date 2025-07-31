# 🏷️ SOCAR B2B 프로젝트 라벨 정의

이 파일은 GitHub Issues와 Pull Requests에서 사용할 라벨들을 정의합니다.

## 라벨 생성 스크립트

다음 스크립트를 실행하여 모든 라벨을 자동으로 생성할 수 있습니다:

```bash
#!/bin/bash

# GitHub CLI를 사용하여 라벨 생성
# 사전에 'gh auth login' 으로 인증 필요

echo "🏷️ SOCAR B2B 프로젝트 라벨 생성 중..."

# 우선순위 라벨
gh label create "priority: critical" --color "B60205" --description "즉시 처리가 필요한 중요한 이슈"
gh label create "priority: high" --color "D93F0B" --description "높은 우선순위 이슈"
gh label create "priority: medium" --color "FBCA04" --description "보통 우선순위 이슈"
gh label create "priority: low" --color "0E8A16" --description "낮은 우선순위 이슈"

# 작업 유형 라벨
gh label create "type: feature" --color "1D76DB" --description "새로운 기능 요청"
gh label create "type: bug" --color "D73A4A" --description "버그 리포트"
gh label create "type: documentation" --color "0075CA" --description "문서 관련 작업"
gh label create "type: enhancement" --color "A2EEEF" --description "기능 개선"
gh label create "type: agentforce" --color "7057FF" --description "Agentforce 관련 작업"
gh label create "type: performance" --color "D4C5F9" --description "성능 개선"
gh label create "type: security" --color "B60205" --description "보안 관련 이슈"

# 컴포넌트 라벨
gh label create "component: apex" --color "FF6B6B" --description "Apex 클래스 관련"
gh label create "component: lwc" --color "4ECDC4" --description "Lightning Web Components"
gh label create "component: flow" --color "45B7D1" --description "Salesforce Flow"
gh label create "component: agentforce" --color "7057FF" --description "Agentforce Actions/Topics"
gh label create "component: reporting" --color "96CEB4" --description "리포팅 및 대시보드"
gh label create "component: integration" --color "FFEAA7" --description "외부 시스템 연동"

# 영역 라벨
gh label create "area: socar-core" --color "74B9FF" --description "SOCAR 핵심 비즈니스 로직"
gh label create "area: payment" --color "00B894" --description "결제 시스템"
gh label create "area: order" --color "FDCB6E" --description "주문 관리"
gh label create "area: customer" --color "E17055" --description "고객 관리"
gh label create "area: analytics" --color "A29BFE" --description "분석 및 리포팅"
gh label create "area: ai" --color "6C5CE7" --description "AI 및 자동화"

# 상태 라벨
gh label create "status: blocked" --color "D73A4A" --description "작업이 차단된 상태"
gh label create "status: stale" --color "EDEDED" --description "오래된 이슈"
gh label create "status: needs-review" --color "FBCA04" --description "리뷰가 필요한 상태"
gh label create "status: in-progress" --color "1D76DB" --description "현재 작업 중"
gh label create "status: testing" --color "BFD4F2" --description "테스트 진행 중"

# 크기/난이도 라벨
gh label create "size: xs" --color "C2E0C6" --description "매우 작은 작업 (1-2시간)"
gh label create "size: s" --color "7FDBDA" --description "작은 작업 (반나절)"
gh label create "size: m" --color "F7DC6F" --description "중간 작업 (1-2일)"
gh label create "size: l" --color "F8C471" --description "큰 작업 (3-5일)"
gh label create "size: xl" --color "EC7063" --description "매우 큰 작업 (1주 이상)"

# 특별 라벨
gh label create "good first issue" --color "7057FF" --description "신규 기여자에게 좋은 이슈"
gh label create "help wanted" --color "008672" --description "도움이 필요한 이슈"
gh label create "question" --color "D876E3" --description "질문이나 토론"
gh label create "duplicate" --color "CFD3D7" --description "중복된 이슈"
gh label create "invalid" --color "E4E669" --description "유효하지 않은 이슈"
gh label create "wontfix" --color "FFFFFF" --description "수정하지 않을 이슈"

echo "✅ 모든 라벨이 성공적으로 생성되었습니다!"
```

## 라벨 사용 가이드

### 필수 라벨
모든 이슈는 다음 라벨을 반드시 포함해야 합니다:
- **하나의 우선순위 라벨**: `priority: *`
- **하나의 작업 유형 라벨**: `type: *`

### 선택적 라벨
필요에 따라 추가할 수 있습니다:
- **컴포넌트 라벨**: 관련 기술 스택
- **영역 라벨**: 비즈니스 도메인
- **크기 라벨**: 작업 추정치

### 자동 라벨링
GitHub Actions를 통해 다음 라벨들은 자동으로 적용됩니다:
- 이슈 제목에 `[AGENTFORCE]`가 포함된 경우: `type: agentforce`, `component: agentforce`
- 이슈 제목에 `[BUG]`가 포함된 경우: `type: bug`, `priority: high`
- 이슈 제목에 `[DOCS]`가 포함된 경우: `type: documentation`

### 라벨 조합 예시

#### 🆕 새로운 기능
```
labels: ["type: feature", "priority: medium", "component: lwc", "area: order", "size: m"]
```

#### 🐛 버그 수정
```
labels: ["type: bug", "priority: high", "component: apex", "area: payment"]
```

#### 🤖 Agentforce 작업
```
labels: ["type: agentforce", "priority: medium", "component: agentforce", "area: ai", "size: l"]
```

## 라벨 색상 가이드

### 우선순위 (빨강 계열)
- Critical: `#B60205` (진한 빨강)
- High: `#D93F0B` (주황빨강)
- Medium: `#FBCA04` (노랑)
- Low: `#0E8A16` (초록)

### 작업 유형 (파랑 계열)
- Feature: `#1D76DB` (파랑)
- Enhancement: `#A2EEEF` (연한 파랑)
- Documentation: `#0075CA` (진한 파랑)

### 특별 항목
- Agentforce: `#7057FF` (보라)
- Bug: `#D73A4A` (빨강)
- Security: `#B60205` (진한 빨강)

---

**🎨 Vibe Coding Color Theory**: 색상은 감정을 전달합니다. 라벨 색상을 통해 이슈의 긴급성과 중요도를 직관적으로 느낄 수 있도록 설계했습니다! 🌈

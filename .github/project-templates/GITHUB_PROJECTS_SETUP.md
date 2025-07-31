# 🗂️ SOCAR B2B GitHub Projects 설정 가이드

이 가이드는 SOCAR B2B Salesforce 프로젝트를 위한 GitHub Projects 칸반 보드 설정 방법을 안내합니다.

## 📋 프로젝트 보드 구조

### 🎯 메인 프로젝트: "SOCAR B2B 혁신 플랫폼"

#### 📊 보드 컬럼 구성

1. **📥 Backlog (백로그)**
   - 우선순위가 정해지지 않은 모든 아이템
   - 아이디어 단계의 기능들
   - 장기 계획 항목들

2. **🎯 Ready (준비완료)**
   - 요구사항이 명확히 정의된 작업
   - 우선순위가 정해진 작업
   - 개발 시작 가능한 상태

3. **🚧 In Progress (진행중)**
   - 현재 개발중인 작업들
   - 담당자가 할당된 작업
   - 최대 3-4개 항목으로 제한

4. **👀 In Review (리뷰중)**
   - Pull Request가 생성된 작업
   - 코드 리뷰 대기중
   - QA 테스트 진행중

5. **✅ Done (완료)**
   - 배포 완료된 기능
   - 테스트 통과한 작업
   - 최근 30일간의 완료 항목

## 🏷️ 라벨 시스템

### 우선순위 라벨
- 🔴 `priority: critical` - 즉시 처리 필요
- 🟠 `priority: high` - 높은 우선순위
- 🟡 `priority: medium` - 보통 우선순위  
- 🟢 `priority: low` - 낮은 우선순위

### 작업 유형 라벨
- 🆕 `type: feature` - 새로운 기능
- 🐛 `type: bug` - 버그 수정
- 📚 `type: documentation` - 문서 작업
- 🎨 `type: enhancement` - 기능 개선
- 🤖 `type: agentforce` - Agentforce 관련
- ⚡ `type: performance` - 성능 개선

### 컴포넌트 라벨
- 🏗️ `component: apex` - Apex 클래스
- ⚡ `component: lwc` - Lightning Web Components
- 🔄 `component: flow` - Salesforce Flow
- 🤖 `component: agentforce` - Agentforce Actions/Topics
- 📊 `component: reporting` - 리포팅
- 🔗 `component: integration` - 외부 시스템 연동

### 영역 라벨
- 🚗 `area: socar-core` - SOCAR 핵심 비즈니스
- 💰 `area: payment` - 결제 시스템
- 📋 `area: order` - 주문 관리
- 👥 `area: customer` - 고객 관리
- 📊 `area: analytics` - 분석 및 리포팅

## 🔄 워크플로우 규칙

### 이슈 생성 시
1. 적절한 템플릿 선택
2. 우선순위 라벨 할당
3. 담당자 지정 (선택사항)
4. 마일스톤 설정 (해당하는 경우)

### 작업 진행 시
1. **Backlog → Ready**: 요구사항 명확화 완료
2. **Ready → In Progress**: 개발 시작
3. **In Progress → In Review**: PR 생성
4. **In Review → Done**: 배포 완료

### 자동화 규칙
- PR 생성 시 자동으로 "In Review"로 이동
- PR 머지 시 자동으로 "Done"으로 이동
- 이슈 클로즈 시 자동으로 "Done"으로 이동

## 📈 프로젝트 뷰

### 1. 칸반 보드 뷰 (기본)
- 작업 흐름 시각화
- 병목 지점 파악
- 팀 작업량 분산 확인

### 2. 테이블 뷰
- 상세 정보 확인
- 필터링 및 정렬
- 대량 편집 작업

### 3. 로드맵 뷰
- 마일스톤별 진행상황
- 릴리스 계획 시각화
- 장기 계획 추적

## 🎯 KPI 및 메트릭

### 추적할 지표
- **Lead Time**: Backlog → Done까지 소요시간
- **Cycle Time**: In Progress → Done까지 소요시간
- **Throughput**: 주/월별 완료 이슈 수
- **WIP**: Work In Progress 항목 수

### 정기 리뷰
- **일일 스탠드업**: In Progress 항목 점검
- **주간 리뷰**: 완료 항목 및 블로커 검토  
- **월간 회고**: 프로세스 개선점 도출

## 🚀 설정 단계

1. **GitHub 저장소로 이동**
2. **"Projects" 탭 클릭**
3. **"New project" 버튼 클릭**
4. **"Board" 템플릿 선택**
5. **위 구조대로 컬럼 생성**
6. **라벨 시스템 적용**
7. **자동화 규칙 설정**

---

**💡 Vibe Coding Tip**: 칸반 보드는 단순한 작업 관리 도구가 아니라, 팀의 에너지와 리듬을 시각화하는 도구입니다. 각 카드가 팀의 열정과 협업의 결과물이라는 마음으로 관리해보세요! 🎵

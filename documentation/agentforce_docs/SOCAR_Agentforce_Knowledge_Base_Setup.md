# 🚗 쏘카 B2B 영업팀 Knowledge Base 구축 가이드

## 📚 Knowledge Articles 생성 목록

### 🎯 1. B2B 모빌리티 솔루션 가이드
**Title**: SOCAR B2B Mobility Solutions Guide
**Content**: 
- 기업용 차량 관리 서비스
- 업무용 차량 임대 옵션
- 모빌리티 비용 절감 전략
- 지속가능한 이동 솔루션

### 📊 2. 리드 스코어링 매트릭스
**Title**: Lead Scoring Matrix for B2B Sales
**Content**:
- 기업 규모별 점수 (직원수, 매출액)
- 업종별 가중치 (제조업, IT, 금융 등)
- 의사결정권자 식별 기준
- 구매 시기 예측 지표

### 🔍 3. 신설법인 발굴 프로세스
**Title**: New Corporation Discovery Process
**Content**:
- 공공 API 활용 방법
- 타겟 업종 선별 기준
- 초기 접촉 전략
- 아웃바운드 영업 스크립트

### 📈 4. 영업 성과 KPI 정의
**Title**: Sales Performance KPIs and Metrics
**Content**:
- 리드 전환율 (목표: 15% → 25%)
- 영업 사이클 (목표: 60일 → 40일)
- 고객 획득 비용 (CAC)
- 생애 가치 (LTV)

### 🎪 5. 고객 여정 분석
**Title**: B2B Customer Journey Analysis
**Content**:
- 인지 단계: 모빌리티 니즈 발생
- 고려 단계: 솔루션 비교 검토
- 결정 단계: 계약 및 도입
- 유지 단계: 서비스 확장

---

## 🛠️ Knowledge Base 설정 방법

### Step 1: Knowledge Settings 활성화
```
Setup → Knowledge → Knowledge Settings
- Enable Salesforce Knowledge: ✅
- Enable Lightning Knowledge: ✅
- Default Language: Korean
```

### Step 2: Data Categories 설정
```
Setup → Data Categories
Categories:
- Sales Process
- Lead Management  
- Customer Success
- Product Information
- Company Policies
```

### Step 3: Article Types 생성
```
Setup → Knowledge → Article Types
Types:
- Sales Guide (영업 가이드)
- Process Document (프로세스 문서)
- FAQ (자주 묻는 질문)
- Product Information (제품 정보)
```

### Step 4: Article 생성 및 발행
```
Knowledge Tab → New Article
- 위의 5개 핵심 Article 생성
- Review 후 Published 상태로 변경
- Lightning Knowledge에서 접근 가능하도록 설정
```

---

## 🔗 Agent와 Knowledge Base 연동

### Agent Action 설정
```
Agent Builder → Actions
- "Answer Questions with Knowledge" 액션 추가
- Knowledge Base 연동 설정
- 검색 범위: Published Articles만
```

### 검색 최적화
```
Knowledge 검색 키워드 최적화:
- "리드", "영업", "B2B", "모빌리티"
- "신설법인", "스코어링", "전환율"
- "고객여정", "KPI", "성과측정"
```

---

## 📊 Data Cloud 없이 가능한 데이터 활용

### Standard Objects 접근
Agent가 자동으로 활용할 수 있는 데이터:
- **Lead Records**: 마케팅팀 유입 리드
- **Opportunity Pipeline**: 영업 기회 현황
- **Account Information**: 기업 고객 데이터
- **Activity History**: 영업 활동 이력

### Custom Objects (필요시 생성)
```
Setup → Object Manager → Create Custom Object
추천 Custom Objects:
- Lead_Score__c: 리드 스코어링 결과
- Prospect_Research__c: 신설법인 발굴 이력
- Sales_KPI__c: 영업 성과 추적
```

---

## 🎯 즉시 실행 액션 플랜

### Phase 1: Knowledge Base 구축 (1주)
1. Salesforce Knowledge 활성화
2. 5개 핵심 Article 생성
3. Data Categories 및 Article Types 설정

### Phase 2: Agent 연동 (1주)
1. Agent Builder에서 Knowledge 연동
2. "Answer Questions with Knowledge" 액션 설정
3. 검색 키워드 최적화

### Phase 3: 테스트 및 최적화 (2주)
1. Agent 응답 품질 테스트
2. Knowledge Article 내용 개선
3. 검색 정확도 향상

---

## 💡 Data Cloud 활성화 시 업그레이드 계획

### 향후 Data Cloud 도입 시
1. **Einstein Data Library** 생성
2. **PDF 문서** 대량 업로드
3. **고급 검색** 및 **AI 인덱싱**
4. **실시간 데이터** 연동

### 현재 vs 향후 비교
| 기능 | 현재 (Knowledge Base) | 향후 (Data Cloud) |
|------|---------------------|-------------------|
| 문서 관리 | Manual Article 생성 | Auto PDF Indexing |
| 검색 정확도 | 키워드 기반 | AI 시맨틱 검색 |
| 업데이트 | 수동 편집 | 자동 동기화 |
| 확장성 | 제한적 | 무제한 |

---

**Created**: 2025년 7월 24일  
**Purpose**: Data Cloud 없이 Agentforce Agent 데이터 소스 구축

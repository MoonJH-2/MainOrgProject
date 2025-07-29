# 🤖 Agentforce Sales Assistant Phase 1 설계

## 📋 Phase 1 목표: 기본 영업 Assistant 구축

### 🎯 **Agent 구성: "SOCAR Sales Assistant"**

#### **핵심 Topics 할당**
```
1. Manage Deals (Standard)
   - 영업 파이프라인 관리
   - 거래 현황 추적
   - Task/콜 로그 관리

2. B2B Email Communication (Custom)
   - Order 이메일 자동화
   - Payment 알림 이메일
   - Asset 갱신 안내

3. General CRM (Standard)
   - 고객 정보 조회
   - 데이터 분석
   - 레코드 요약
```

#### **주요 Actions 매핑**

##### **영업 활동 관리**
```
Topic: Manage Deals
├── Log a Call - 고객 통화 기록
├── Create a To Do - 후속 작업 생성
├── Get Activities Timeline - 고객 접촉 이력
├── Query Records - 거래 현황 조회
└── Get Record Details - 상세 정보 확인
```

##### **이메일 자동화**
```
Topic: B2B Email Communication
├── Draft Order Email - 주문 확인/진행 상황
├── Draft Payment Email - 결제 안내/연체 알림
├── Draft Asset Renewal Email - 갱신 기회 알림
├── Revise Email Draft - 톤 조정/내용 수정
└── Send Generated Email - 실제 전송
```

##### **고객 정보 관리**
```
Topic: General CRM
├── Query Records - 고객 데이터 검색
├── Summarize Record - 고객/거래 요약
├── Update Record - 정보 업데이트
└── Extract Fields And Values - 데이터 추출
```

---

## 🎬 실제 사용 시나리오

### **시나리오 1: 아침 업무 브리핑**
```
영업사원: "오늘 할 일 정리해줘"
AI Agent: 
→ Query Records (오늘 미팅 일정)
→ Get Activities Timeline (팔로업 필요 고객)
→ Create a To Do (우선순위 Task 생성)
```

### **시나리오 2: 고객 미팅 후 처리**
```
영업사원: "ABC 고객과 미팅했어. 제안서 발송 예정이고 다음주 재연락하기로 했어"
AI Agent:
→ Log a Call (미팅 내용 기록)
→ Create a To Do (제안서 발송 Task)
→ Create a To Do (다음주 재연락 알림)
```

### **시나리오 3: 주문 확인 이메일 발송**
```
영업사원: "효원 고객에게 Order 00000167 확인 이메일 보내줘"
AI Agent:
→ Draft Order Email (주문 확인 이메일 생성)
→ Revise Email Draft (필요시 톤 조정)
→ Send Generated Email (실제 전송)
```

---

## 📈 예상 효과

### **즉시 효과**
- ⏰ **시간 절약**: 일일 2-3시간 업무 자동화
- 📧 **이메일 품질 향상**: 일관된 톤, 오타 방지
- 📊 **데이터 정확성**: 수동 입력 오류 최소화

### **중장기 효과**
- 🎯 **영업 성과 향상**: 더 많은 시간을 실제 영업에 집중
- 🤝 **고객 만족도 증대**: 신속하고 정확한 응대
- 📈 **매출 증대**: 갱신 기회 놓침 방지

---

## 🛠️ 구현 단계

### **Week 1: Agent 기본 설정**
1. Agentforce Studio에서 "SOCAR Sales Assistant" 생성
2. Phase 1 Topics 할당 (Manage Deals, B2B Email Communication, General CRM)
3. 기본 Actions 매핑 및 테스트

### **Week 2: 시나리오 테스트 및 최적화**
1. 실제 영업 시나리오 기반 테스트
2. 응답 품질 개선 및 Instructions 최적화
3. 사용자 권한 설정 및 배포 준비

---

## 🔄 다음 Phase 준비

### **Phase 2 예정 기능**
- Slack 완전 통합
- 고급 분석 및 예측
- 자동 보고서 생성
- 모바일 최적화

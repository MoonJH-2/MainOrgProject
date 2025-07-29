# 🎯 B2B Sales Daily Management Topic - Actions 선택 가이드

## ✅ **우선 선택해야 할 핵심 Actions (1순위)**

### 🔥 **배포된 SOCAR 서비스 Actions**
이 Actions들은 우리가 배포한 핵심 서비스들과 직접 연결됩니다:

1. **Draft Order Email** ✅
   - 설명: Order 확인, 진행상황, 배송 관련 이메일 초안을 생성합니다. SOCAR B2B 고객에게 주문 상태에 따른 맞춤형 이메일을 자동으로 작성합니다.
   - 연결 서비스: AgentforceSimpleEmailActions
   - 선택 여부: **필수 선택**

2. **Draft Payment Email** ✅
   - 설명: SOCAR B2B 고객에게 Payment 관련 이메일 초안을 생성합니다.
   - 연결 서비스: AgentforceSimpleEmailActions
   - 선택 여부: **필수 선택**

3. **Draft Asset Renewal Email** ✅
   - 설명: SOCAR B2B 고객에게 Asset 갱신 및 관리 관련 이메일 초안을 생성합니다.
   - 연결 서비스: AgentforceSimpleEmailActions
   - 선택 여부: **필수 선택**

4. **Send Generated Email** ✅
   - 설명: 이전에 생성된 이메일 초안을 실제로 전송합니다.
   - 연결 서비스: AgentforceSendEmailAction
   - 선택 여부: **필수 선택**

5. **Revise Email Draft** ✅
   - 설명: 기존 이메일 초안을 다양한 스타일과 톤으로 수정하고 개선합니다.
   - 연결 서비스: AgentforceEmailRevisionAction
   - 선택 여부: **필수 선택**

## ✅ **추가 선택 권장 Actions (2순위)**

### 📋 **일일 업무 관리 관련**
6. **Create a To Do** ✅
   - 설명: Create a task record based on user input
   - 이유: 일일 브리핑에서 할일 관리 기능 강화
   - 선택 여부: **강력 권장**

7. **Log a Call** ✅
   - 설명: Save a call based on the user input
   - 이유: 미팅 후속처리 및 활동 기록
   - 선택 여부: **강력 권장**

8. **Get Activities Timeline** ✅
   - 설명: Retrieve a timeline of all CRM activities
   - 이유: 일일 브리핑에 활동 히스토리 포함
   - 선택 여부: **강력 권장**

### 📊 **고객 관리 관련**
9. **Get Record Details** ✅
   - 설명: Generates a text blob containing record details
   - 이유: 고객 정보 빠른 조회
   - 선택 여부: **권장**

10. **Query Records** ✅
    - 설명: Finds and retrieves Salesforce CRM records
    - 이유: 동적 데이터 조회 기능
    - 선택 여부: **권장**

11. **Update Record** ✅
    - 설명: Updates fields on a Salesforce CRM record
    - 이유: 레코드 업데이트 기능
    - 선택 여부: **권장**

### 🔍 **데이터 분석 관련**
12. **Query Records with Aggregate** ✅
    - 설명: Answers aggregation questions about Salesforce CRM data
    - 이유: 집계 데이터 분석 (매출, 건수 등)
    - 선택 여부: **권장**

13. **Summarize Record** ✅
    - 설명: Summarizes a single Salesforce CRM record
    - 이유: 고객/거래 요약 정보 제공
    - 선택 여부: **권장**

## ❌ **선택하지 말아야 할 Actions**

### 🚫 **현재 Topic과 관련 없는 Actions**
- Slack 관련 Actions (별도 Topic에서 처리)
- Case 관리 Actions (고객 서비스용)
- Security 관련 Actions
- Policy 관련 Actions
- Password Reset Actions
- Experience Builder Actions

## 📋 **최종 선택 체크리스트**

### **필수 선택 (5개)** ✅
- [ ] Draft Order Email
- [ ] Draft Payment Email  
- [ ] Draft Asset Renewal Email
- [ ] Send Generated Email
- [ ] Revise Email Draft

### **강력 권장 (3개)** ⭐
- [ ] Create a To Do
- [ ] Log a Call
- [ ] Get Activities Timeline

### **추가 권장 (5개)** 📊
- [ ] Get Record Details
- [ ] Query Records
- [ ] Update Record
- [ ] Query Records with Aggregate
- [ ] Summarize Record

## 🎯 **선택 전략**

1. **1단계**: 필수 5개 Actions 먼저 선택
2. **2단계**: 강력 권장 3개 Actions 추가 선택
3. **3단계**: 필요에 따라 추가 권장 Actions 선택
4. **주의**: 한 번에 너무 많이 선택하지 말고, 핵심 기능부터 시작

---

**다음 단계: 위의 필수 5개 Actions부터 체크박스 선택 시작! 🚀**

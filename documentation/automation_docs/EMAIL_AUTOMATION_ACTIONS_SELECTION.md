# 🎯 SOCAR B2B Customer Email Automation - Actions 선택 가이드

## ✅ **필수 선택 Actions (1순위)** - 배포된 핵심 서비스

### 🔥 **SOCAR 전용 이메일 Actions (5개)**
이 Actions들은 배포된 AgentforceSimpleEmailActions 서비스와 직접 연결됩니다:

1. **Draft Order Email** ✅ (Item 26)
   - 설명: Order 확인, 진행상황, 배송 관련 이메일 초안을 생성합니다. SOCAR B2B 고객에게 주문 상태에 따른 맞춤형 이메일을 자동으로 작성합니다.
   - 연결 서비스: AgentforceOrderEmailAction
   - 선택 여부: **필수 선택**

2. **Draft Payment Email** ✅ (Item 27)
   - 설명: SOCAR B2B 고객에게 Payment 관련 이메일 초안을 생성합니다.
   - 연결 서비스: AgentforcePaymentEmailAction
   - 선택 여부: **필수 선택**

3. **Draft Asset Renewal Email** ✅ (Item 24)
   - 설명: SOCAR B2B 고객에게 Asset 갱신 및 관리 관련 이메일 초안을 생성합니다.
   - 연결 서비스: AgentforceAssetEmailAction
   - 선택 여부: **필수 선택**

4. **Revise Email Draft** ✅ (Item 66)
   - 설명: 기존 이메일 초안을 다양한 스타일과 톤으로 수정하고 개선합니다.
   - 연결 서비스: AgentforceEmailRevisionAction
   - 선택 여부: **필수 선택**

5. **Send Generated Email** ✅ (Item 70)
   - 설명: 이전에 생성된 이메일 초안을 실제로 전송합니다.
   - 연결 서비스: AgentforceSendEmailAction
   - 선택 여부: **필수 선택**

## ✅ **강력 권장 Actions (2순위)** ⭐⭐

### 📧 **범용 이메일 기능**
6. **Draft or Revise Email** ✅ (Item 25)
   - 설명: Creates an email draft or revises the latest generated email based on user input
   - 이유: 일반적인 이메일 생성/수정 기능 보완
   - 선택 여부: **강력 권장**

### 📊 **고객 정보 조회**
7. **Get Record Details** ✅ (Item 45)
   - 설명: Generates a text blob containing record details
   - 이유: 이메일 개인화를 위한 고객 정보 조회
   - 선택 여부: **강력 권장**

8. **Identify Customer By Email** ✅ (Item 49)
   - 설명: Identify a customer by their email address and return their contact record
   - 이유: 이메일 주소로 고객 식별
   - 선택 여부: **강력 권장**

### 🔍 **레코드 관리**
9. **Query Records** ✅ (Item 60)
   - 설명: Finds and retrieves Salesforce CRM records
   - 이유: 동적 고객 데이터 조회로 이메일 개인화
   - 선택 여부: **강력 권장**

10. **Identify Record by Name** ✅ (Item 52)
    - 설명: Searches for Salesforce CRM records by name
    - 이유: 고객명으로 레코드 검색
    - 선택 여부: **강력 권장**

## ✅ **추가 권장 Actions (3순위)** ⭐

### 📈 **주문/고객 관리**
11. **Get Order By Order Number** ✅ (Item 41)
    - 설명: Returns the order information associated with a given contact ID and order number
    - 이유: 주문 관련 이메일 생성 시 상세 정보 조회
    - 선택 여부: **권장**

12. **Get Orders By Contact** ✅ (Item 42)
    - 설명: Returns a list of orders associated with a given contact record
    - 이유: 고객별 주문 히스토리 조회
    - 선택 여부: **권장**

13. **Get Activities Timeline** ✅ (Item 32)
    - 설명: Retrieve a timeline of all CRM activities
    - 이유: 고객 커뮤니케이션 히스토리 파악
    - 선택 여부: **권장**

### 📝 **기록 관리**
14. **Create a To Do** ✅ (Item 13)
    - 설명: Create a task record based on user input
    - 이유: 이메일 후속 조치 작업 생성
    - 선택 여부: **권장**

15. **Log a Call** ✅ (Item 56)
    - 설명: Save a call based on the user input
    - 이유: 이메일 관련 통화 기록
    - 선택 여부: **권장**

## ❌ **선택하지 말아야 할 Actions**

### 🚫 **현재 Topic과 관련 없는 Actions**
- **Slack 관련 Actions** (Items 2, 5, 10-12, 55, 57-58, 67-68, 71-74, 76)
- **Case 관리 Actions** (Items 1, 15-16, 34, 37-39)
- **Security 관련 Actions** (Items 8, 47-48)
- **Policy 관련 Actions** (Items 43-44, 51)
- **Password/Verification Actions** (Items 63-64, 69, 80)

## 📋 **최종 선택 체크리스트**

### **필수 선택 (5개)** ✅
- [ ] Item 24: Draft Asset Renewal Email
- [ ] Item 26: Draft Order Email
- [ ] Item 27: Draft Payment Email
- [ ] Item 66: Revise Email Draft
- [ ] Item 70: Send Generated Email

### **강력 권장 (5개)** ⭐
- [ ] Item 25: Draft or Revise Email
- [ ] Item 45: Get Record Details
- [ ] Item 49: Identify Customer By Email
- [ ] Item 52: Identify Record by Name
- [ ] Item 60: Query Records

### **추가 권장 (5개)** 📊
- [ ] Item 13: Create a To Do
- [ ] Item 32: Get Activities Timeline
- [ ] Item 41: Get Order By Order Number
- [ ] Item 42: Get Orders By Contact
- [ ] Item 56: Log a Call

## 🎯 **선택 전략**

### **단계별 선택 방법:**
1. **1단계**: 필수 5개 Actions 먼저 선택 (SOCAR 전용 이메일 서비스)
2. **2단계**: 강력 권장 5개 Actions 추가 (범용 이메일 기능 + 고객 조회)
3. **3단계**: 필요에 따라 추가 권장 Actions 선택 (주문 관리 + 기록 관리)

### **총 권장 선택 수:** 10-15개 Actions

---

**다음 단계: 위의 필수 5개 Actions부터 체크박스 선택 시작! 🚀**

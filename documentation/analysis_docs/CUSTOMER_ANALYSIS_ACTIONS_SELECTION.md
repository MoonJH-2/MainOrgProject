# 🎯 SOCAR B2B Customer Analysis - Actions 선택 가이드

## ✅ **필수 선택 Actions (1순위)** - 고객 분석 핵심 기능

### 📊 **데이터 조회 및 분석 Actions (5개)**

1. **Query Records with Aggregate** ✅ (Item 48)
   - 설명: Answers aggregation questions (count, sum, max, min, average) about Salesforce CRM data
   - 이유: 고객 분석의 핵심! 매출 합계, 평균 결제 주기, 고객 수 등 집계 분석
   - 연결 기능: 이탈 위험도 계산, 매출 예측 분석
   - 선택 여부: **필수 선택**

2. **Get Record Details** ✅ (추가 검색 필요)
   - 설명: Generates a text blob containing record details, including object fields and values
   - 이유: 고객 360도 뷰 제공을 위한 상세 정보 조회
   - 연결 기능: 고객 종합 정보 및 관계 현황 파악
   - 선택 여부: **필수 선택** (목록에 없으면 유사 기능 대체)

3. **Summarize Record** ✅ (Item 60)
   - 설명: Summarizes a single Salesforce CRM record
   - 이유: 고객/거래 정보 요약으로 빠른 인사이트 제공
   - 연결 기능: 고객 360도 뷰의 핵심 요약 기능
   - 선택 여부: **필수 선택**

4. **Query Records** ✅ (추가 검색 필요)
   - 설명: Finds and retrieves Salesforce CRM records based on user input
   - 이유: 동적 고객 데이터 조회로 분석 기반 구축
   - 연결 기능: 고객 행동 패턴 분석, 결제 이력 조회
   - 선택 여부: **필수 선택** (목록에 없으면 유사 기능 대체)

5. **Get Activity Details** ✅ (Item 27)
   - 설명: Provides data about an activity record (Call, Email, Event, Task)
   - 이유: 고객과의 커뮤니케이션 히스토리 분석
   - 연결 기능: 최적 연락 타이밍 추천, 고객 관계 분석
   - 선택 여부: **필수 선택**

## ✅ **강력 권장 Actions (2순위)** ⭐⭐

### 🔍 **고객 식별 및 검색**
6. **Identify Record by Name** ✅ (추가 검색 필요)
   - 설명: Searches for Salesforce CRM records by name
   - 이유: 고객명으로 빠른 레코드 검색 및 분석 시작
   - 선택 여부: **강력 권장** (목록에 없음)

7. **Identify Object by Name** ✅ (Item 40)
   - 설명: Finds the Salesforce object API name by extracting an object name
   - 이유: 동적 객체 식별로 유연한 분석 지원
   - 선택 여부: **강력 권장**

### 📈 **분석 지원 기능**
8. **Extract Fields And Values From User Input** ✅ (Item 24)
   - 설명: Extracts Salesforce CRM record fields and their values from user input
   - 이유: 사용자 입력을 구조화된 분석 요청으로 변환
   - 선택 여부: **강력 권장**

9. **Create an Account Executive Brief** ✅ (Item 13)
   - 설명: Generate an executive brief of that account grounded with details
   - 이유: 고객 분석 결과를 임원진 브리핑 형태로 제공
   - 선택 여부: **강력 권장**

### 🏷️ **분류 및 라벨링**
10. **Label a Record** ✅ (Item 43)
    - 설명: Assign or apply a label to another CRM record such as Account
    - 이유: 분석 결과에 따른 고객 세분화 및 라벨링
    - 선택 여부: **강력 권장**

## ✅ **추가 권장 Actions (3순위)** ⭐

### 📅 **활동 관리**
11. **Return Calendar Link** ✅ (Item 52)
    - 설명: Adds a calendar link to the agent's response
    - 이유: 최적 연락 타이밍 추천 후 실제 미팅 스케줄링
    - 선택 여부: **권장**

### 🎯 **개인화 기능**
12. **Personalization: Get Context** ✅ (Item 47)
    - 설명: Improve agent decisioning with real-time access to personalization data
    - 이유: 개인화된 고객 분석 및 추천 강화
    - 선택 여부: **권장**

### 📞 **고객 관리**
13. **Create Sales Contact Record** ✅ (Item 16)
    - 설명: Searches for a matching Contact record. If not found, creates a new one
    - 이유: 분석 과정에서 새로운 연락처 발견 시 자동 생성
    - 선택 여부: **권장**

14. **Update Record** ✅ (Item 63)
    - 설명: Updates fields on a Salesforce CRM record
    - 이유: 분석 결과를 바탕으로 고객 레코드 업데이트
    - 선택 여부: **권장**

## ❌ **선택하지 말아야 할 Actions**

### 🚫 **현재 Topic과 관련 없는 Actions**
- **Slack 관련 Actions** (Items 2, 5, 10-12, 44-46, 53-54, 56-59, 61)
- **Case 관리 Actions** (Items 1, 14-15, 28, 31-33)
- **Security 관련 Actions** (Items 8, 38-39)
- **Policy 관련 Actions** (Items 35-36, 41)
- **Password/Verification Actions** (Items 50-51, 55, 65)
- **Delivery/Reservation Actions** (Items 25-26, 34, 37)
- **Permission 관련 Actions** (Items 29-30, 42)

## 📋 **최종 선택 체크리스트**

### **필수 선택 (5개)** ✅
- [ ] Item 48: Query Records with Aggregate
- [ ] Item 60: Summarize Record
- [ ] Item 27: Get Activity Details
- [ ] **누락된 중요 Actions** (다른 Topic에서 사용 중일 수 있음):
  - Get Record Details
  - Query Records

### **강력 권장 (5개)** ⭐
- [ ] Item 40: Identify Object by Name
- [ ] Item 24: Extract Fields And Values From User Input
- [ ] Item 13: Create an Account Executive Brief
- [ ] Item 43: Label a Record
- [ ] **누락**: Identify Record by Name

### **추가 권장 (4개)** 📊
- [ ] Item 52: Return Calendar Link
- [ ] Item 47: Personalization: Get Context
- [ ] Item 16: Create Sales Contact Record
- [ ] Item 63: Update Record

## 🎯 **선택 전략**

### **우선 선택 방법:**
1. **1단계**: 필수 3개 Actions 먼저 선택 (현재 목록에 있는 것들)
2. **2단계**: 강력 권장 Actions 중 목록에 있는 것들 선택
3. **3단계**: 추가 권장 Actions 선별 선택

### **현실적 선택 수:** 8-12개 Actions

---

## 🚨 **중요 발견사항**

**현재 Actions 목록에서 핵심 Actions 일부가 누락되어 있습니다:**
- `Get Record Details` (고객 상세 정보 조회)
- `Query Records` (일반 레코드 검색)
- `Identify Record by Name` (이름으로 레코드 검색)

**이는 이전 Topics에서 이미 선택되었기 때문일 수 있습니다.**

---

**다음 단계: 위의 필수 3개 Actions부터 체크박스 선택 시작! 🚀**

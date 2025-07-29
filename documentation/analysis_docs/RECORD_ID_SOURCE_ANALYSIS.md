# 🔍 Record ID 출처 및 해결 분석

## 📊 **Record ID 오류 분석 결과**

### **현재 나타나는 Record ID들:**
```yaml
오류 1: "0053m00000ABCDE" 
- 객체: Contact (005로 시작)
- 상태: 존재하지 않는 샘플 ID

오류 2: "0013m00000ABCDE"
- 객체: Account (001로 시작)  
- 상태: 존재하지 않는 샘플 ID
```

---

## 🎯 **Record ID 출처 위치**

### **1. Agentforce Actions 설정에서 하드코딩** 🔧
```yaml
위치: Agentforce Studio > Topics > Actions 설정
문제: Get Activities Timeline Action에서 샘플 Record ID 사용
원인: Action 생성 시 테스트용 하드코딩된 값이 그대로 남음
```

### **2. Salesforce Object ID 체계** 📋
```yaml
Salesforce ID 구조: [3자리 접두사][12자리 고유값]

001: Account (고객사)
003: Contact (담당자)  
005: Contact (개인)
00Q: Lead (리드)
006: Opportunity (영업기회)
00T: Task (할일)
00U: Event (일정)
```

### **3. 현재 오류의 의미** ❌
```yaml
"0053m00000ABCDE":
- Contact 객체의 샘플 ID
- Get Activities Timeline이 Contact 기준으로 Activities 조회 시도
- 실제로는 존재하지 않는 테스트 ID

"0013m00000ABCDE":  
- Account 객체의 샘플 ID
- Account 기준으로 Activities 조회 시도
- 실제로는 존재하지 않는 테스트 ID
```

---

## 🔧 **Record ID 동적 처리 방법**

### **방법 1: Actions 설정에서 Record ID 제거** 🏆
```yaml
현재 문제가 되는 Action:
- Get Activities Timeline

해결 방법:
1. Topic Actions 편집 모드 진입
2. Get Activities Timeline Action 설정
3. Record ID 필드를 "Use context from conversation" 로 변경
4. 또는 해당 Action 제거하고 다른 Action으로 대체
```

### **방법 2: 실제 Record ID 사용** 📊
```yaml
실제 Account ID 확인 방법:
1. Developer Console > Query Editor
2. SELECT Id, Name FROM Account LIMIT 5
3. 실제 존재하는 Account ID를 Actions에 설정
```

### **방법 3: Record ID 없는 Actions로 대체** ⚡
```yaml
대체 가능한 Actions:
- Query Records with Aggregate → 전체 데이터 조회
- Get Current User Info → 현재 사용자 정보
- Create Record → 새 레코드 생성
- Send Email → 이메일 발송
```

---

## 🚀 **즉시 해결 방법**

### **Step 1: 실제 Record ID 확인 (2분)**
```sql
-- Developer Console에서 실행
SELECT Id, Name, Type FROM Account LIMIT 5;
SELECT Id, FirstName, LastName FROM Contact LIMIT 5;
SELECT Id, Subject, ActivityDate FROM Task WHERE OwnerId = :$User.Id LIMIT 5;
```

### **Step 2: Actions 재설정 (5분)**
```yaml
1. Agentforce Studio > SOCAR Sales Agent > Topics
2. B2B Sales Daily Management 클릭
3. Actions 탭에서 "Get Activities Timeline" 편집
4. Record ID 설정을 동적으로 변경 또는 Action 제거
```

### **Step 3: 대체 Actions 추가 (5분)**
```yaml
추가할 Actions:
1. Query Records with Aggregate
   - Object: Task
   - Filter: OwnerId = Current User, ActivityDate = Today

2. Get Current User Info
   - 현재 사용자 정보 조회

3. Create Record  
   - Object: Task
   - 새 할일 생성 기능
```

---

## 📋 **구체적인 실행 계획**

### **현재 즉시 실행 (Quick Console):**
```sql
-- 1. 실제 데이터 확인
SELECT Id, Name FROM Account WHERE Name LIKE '%SOCAR%' OR Name LIKE '%테스트%' LIMIT 5;

-- 2. 현재 사용자의 Task 확인  
SELECT Id, Subject, ActivityDate, Status FROM Task 
WHERE OwnerId = :$User.Id AND ActivityDate = TODAY;

-- 3. Contact 정보 확인
SELECT Id, Name, Email FROM Contact LIMIT 5;
```

### **결과에 따른 Action Plan:**
```yaml
Case 1: 실제 Account/Contact 존재
→ Actions에서 실제 ID로 업데이트

Case 2: 데이터 없음  
→ 테스트 데이터 생성 후 Actions 업데이트

Case 3: 권한 문제
→ Record ID 없는 Actions로 대체
```

---

## 🎯 **핵심 결론**

### **Record ID 출처:**
1. **Agentforce Actions 설정에서 하드코딩된 샘플 값**
2. **Get Activities Timeline Action이 테스트 ID 사용**
3. **실제 Salesforce org 데이터와 연결 안됨**

### **해결 우선순위:**
1. ✅ **실제 Record ID 확인** (Quick Query 실행)
2. ✅ **Actions 설정 수정** (동적 Record ID 사용)
3. ✅ **대체 Actions 사용** (Record ID 불필요한 Actions)

---

## 🔥 **지금 바로 실행할 것**

**Quick Console에서 바로 실행:**
```sql
SELECT Id, Name FROM Account LIMIT 3;
SELECT Id, Subject FROM Task WHERE OwnerId = :$User.Id AND ActivityDate = TODAY LIMIT 3;
```

**결과를 보고 실제 ID가 있으면 Actions에 적용, 없으면 테스트 데이터 생성!** 🚀

**핵심: Record ID는 Actions 설정에서 나오는 하드코딩된 샘플값입니다!** ⚡

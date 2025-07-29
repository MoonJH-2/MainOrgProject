# 🎯 Account ID 동적 설정 완전 가이드

## 📊 **현재 문제 상황**
- **하드코딩된 샘플 ID**: `"0013m00000ABCDE"` (존재하지 않음)
- **필요한 것**: 실제 존재하는 Account ID
- **목표**: Actions에서 동적으로 실제 Account ID 사용

---

## 🔍 **Step 1: 실제 Account ID 확인**

### **방법 1: Developer Console 사용 (권장)**
```sql
-- Salesforce org에서 Developer Console > Query Editor
SELECT Id, Name, Type, Industry 
FROM Account 
WHERE IsDeleted = false 
ORDER BY CreatedDate DESC 
LIMIT 10;
```

### **방법 2: Quick Console 사용**
```sql
-- VS Code Quick Console에서
SELECT Id, Name FROM Account LIMIT 5;
```

### **방법 3: 테스트 Account 생성**
```apex
-- Anonymous Apex로 테스트 Account 생성
Account testAccount = new Account(
    Name = 'SOCAR B2B 테스트 고객',
    Type = 'Customer - Direct',
    Industry = 'Transportation',
    BillingCountry = 'South Korea'
);
insert testAccount;
System.debug('Created Account ID: ' + testAccount.Id);
```

---

## 🔧 **Step 2: Agentforce Actions 동적 설정**

### **현재 문제가 되는 Action 위치:**
```yaml
경로: Agentforce Studio > SOCAR Sales Agent > Topics > B2B Sales Daily Management > Actions
문제 Action: "Get Activities Timeline"
설정 항목: Record ID 필드
```

### **동적 설정 방법 A: Context 기반 (권장)**
```yaml
Record ID 설정을 다음으로 변경:
❌ 기존: "0013m00000ABCDE" (하드코딩)
✅ 변경: "Use context from conversation"
✅ 또는: "Use current user's default account"
```

### **동적 설정 방법 B: 실제 ID로 교체**
```yaml
1. 위에서 조회한 실제 Account ID 복사
2. Actions 설정에서 Record ID 필드에 실제 ID 입력
3. 예: "001XXXXXXXXXX" (실제 ID로 교체)
```

---

## 🎯 **Step 3: 구체적인 실행 계획**

### **3.1 즉시 실행: Account ID 확인**
```bash
목표: 실제 존재하는 Account ID 1개 이상 확보
방법: Developer Console 또는 테스트 데이터 생성
소요시간: 3-5분
```

**Developer Console에서 바로 실행:**
```sql
SELECT Id, Name, Type FROM Account WHERE Name != null LIMIT 5;
```

**결과 예시:**
```
Id: 001XXXXXXXXXX | Name: 삼성전자 | Type: Customer
Id: 001YYYYYYYYYY | Name: LG화학 | Type: Prospect  
```

### **3.2 Actions 설정 변경**
```bash
목표: Get Activities Timeline Action에서 실제 ID 사용
방법: Agentforce Studio에서 Actions 편집
소요시간: 5-10분
```

**실행 순서:**
1. **Agentforce Studio 접속**
2. **SOCAR Sales Agent > Topics**
3. **B2B Sales Daily Management 클릭**
4. **Actions 탭에서 "Get Activities Timeline" 찾기**
5. **편집 버튼 클릭**
6. **Record ID 필드 수정:**
   - 기존: `0013m00000ABCDE`
   - 신규: `001XXXXXXXXXX` (실제 조회한 ID)
7. **저장 및 활성화**

---

## 🚀 **Step 4: 즉시 테스트**

### **변경 후 바로 테스트:**
```bash
Agentforce Conversation에서 입력:
"내 오늘 일정 보여줘"
```

### **예상 결과:**
```yaml
성공 시:
✅ Record ID 오류 해결
✅ Activities Timeline 정상 조회
✅ 실제 Account 기반 일정 표시

실패 시:
❌ 권한 문제 → Profile 설정 확인 필요
❌ 데이터 없음 → 해당 Account에 Activities 생성 필요
```

---

## 📋 **대안 방법들**

### **대안 1: Record ID 없는 Actions로 교체**
```yaml
현재 Actions:
❌ Get Activities Timeline (Record ID 필요)

대체 Actions:
✅ Query Records with Aggregate (Record ID 불필요)
✅ Get Current User Info (User 기반)
✅ Create Record (새 Task 생성)
```

### **대안 2: User 기반 Activities 조회**
```yaml
설정 변경:
- Object: Task/Event
- Filter: OwnerId = Current User
- Date Range: Today
```

### **대안 3: 여러 Account ID 순환 사용**
```yaml
복수 Account 설정:
1. 주요 고객사 Account ID들을 미리 파악
2. Actions에서 가장 활발한 Account ID 사용
3. 정기적으로 업데이트
```

---

## 🎯 **지금 바로 실행할 것**

### **1순위: Account ID 확인 (지금 즉시)**
```sql
-- Developer Console > Query Editor에서
SELECT Id, Name, Type FROM Account 
WHERE IsDeleted = false 
ORDER BY LastModifiedDate DESC 
LIMIT 5;
```

### **2순위: Actions 설정 변경**
```bash
위에서 나온 Account ID 중 하나를 복사해서
Agentforce Actions 설정에 적용
```

### **3순위: 즉시 테스트**
```bash
"내 오늘 일정 보여줘" 다시 입력하여 확인
```

---

## 🔥 **핵심 포인트**

1. **실제 Account ID는 반드시 존재하는 ID여야 함**
2. **Get Activities Timeline은 해당 Account의 관련 Activities 조회**
3. **동적 설정이 가장 유연하지만, 실제 ID도 효과적**
4. **테스트 후 다른 Topics도 동일하게 적용 가능**

---

## 🎉 **성공 시 기대 효과**

```yaml
Before:
❌ "Record not found" 오류
❌ 하드코딩된 샘플 ID

After:  
✅ 실제 Account 기반 Activities 조회
✅ 정상적인 일정 및 Task 표시
✅ 완전한 영업 관리 기능 작동
```

**지금 바로 Developer Console에서 Account ID를 확인해보세요!** 🚀

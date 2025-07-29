# 🛠️ Agentforce Record ID 오류 완전 해결 가이드

## 📊 **오류 분석 결과**

### ✅ **정상 작동하는 것들:**
- **Topic Selection 완벽 작동** (0.23-0.32초)
- **한국어 명령어 처리 완벽**
- **4개 Topics 모두 정확히 매칭됨**
- **Action Selection 프로세스 정상**
- **이메일 Topic은 부분적으로 작동** (입력 폼 표시됨)

### ❌ **문제점:**
- **하드코딩된 샘플 Record ID들이 존재하지 않음**
- **Get Activities Timeline Action이 잘못된 ID로 호출됨**
- **실제 Salesforce 데이터와 연결되지 않음**

---

## 🎯 **근본 원인 분석**

### **1. Actions 설정 문제**
```yaml
현재 상황:
- Get Activities Timeline Action이 샘플 Record ID로 하드코딩됨
- "0053m00000ABCDE", "0013m00000ABCDE" 등 존재하지 않는 ID
- 실제 User나 Account 데이터와 연결되지 않음

해결 필요:
- Actions에서 Record ID를 동적으로 가져오도록 수정
- 또는 Record ID 없이 작동하는 Actions로 대체
```

### **2. 권한 및 데이터 접근 문제**
```yaml
현재 상황:
- Salesforce org에 실제 Activities/Tasks 데이터 부족
- User Profile의 데이터 접근 권한 제한 가능성
- Timeline Actions이 필요한 객체에 접근 불가

해결 필요:
- 실제 데이터 존재 여부 확인
- User 권한 설정 검토
- Alternative Actions 활용
```

---

## 🔧 **즉시 해결 방법 (3가지 옵션)**

### **옵션 1: 커스텀 서비스 직접 호출 (권장)** 🏆

#### **Step 1: Anonymous Apex로 서비스 테스트**
```apex
// 배포된 AgentforceSalesAssistantService 직접 테스트
List<AgentforceSalesAssistantService.AgentforceRequest> requests = 
    new List<AgentforceSalesAssistantService.AgentforceRequest>();

AgentforceSalesAssistantService.AgentforceRequest request = 
    new AgentforceSalesAssistantService.AgentforceRequest();
request.requestType = 'getDailyBriefing';
request.userId = UserInfo.getUserId();
request.targetDate = Date.today();
requests.add(request);

List<AgentforceSalesAssistantService.AgentforceResponse> responses = 
    AgentforceSalesAssistantService.processAgentforceRequests(requests);

System.debug('Daily Briefing: ' + responses[0].responseMessage);
```

#### **Step 2: 이메일 서비스 테스트**
```apex
// AgentforceSimpleEmailActions 직접 테스트
List<AgentforceSimpleEmailActions.EmailRequest> emailRequests = 
    new List<AgentforceSimpleEmailActions.EmailRequest>();

AgentforceSimpleEmailActions.EmailRequest emailReq = 
    new AgentforceSimpleEmailActions.EmailRequest();
emailReq.emailType = 'general';
emailReq.customerEmail = 'eetd0000@tiger.com';
emailReq.subject = '일반 안내사항';
emailReq.additionalContext = '고객님께 드리는 일반 안내입니다.';
emailRequests.add(emailReq);

List<AgentforceSimpleEmailActions.EmailResponse> emailResponses = 
    AgentforceSimpleEmailActions.generateEmailDraft(emailRequests);

System.debug('Generated Email: ' + emailResponses[0].emailBody);
```

---

### **옵션 2: Topics Actions 재설정** ⚙️

#### **2.1 B2B Sales Daily Management Topic 수정**

**문제가 되는 Actions 제거/교체:**
```yaml
제거할 Actions:
- Get Activities Timeline (Record ID 의존적)
- Get Record Summary (Record ID 의존적)

추가할 Actions:
- Query Records with Aggregate (전체 데이터 조회)
- Create Record (새 Task 생성)
- Update Record (기존 레코드 업데이트)
```

#### **2.2 새로운 Actions 조합 설정**
```yaml
Daily Management를 위한 추천 Actions:
1. Query Records with Aggregate → Task 조회
2. Summarize Record → 요약 정보
3. Send Email → 이메일 알림
4. Create Record → 새 Task 생성
5. Update Record → Task 상태 업데이트
```

---

### **옵션 3: 샘플 데이터 생성** 📊

#### **3.1 테스트용 Account 생성**
```apex
// 테스트용 Account 생성
Account testAccount = new Account(
    Name = 'SOCAR 테스트 고객',
    Type = 'Customer',
    Industry = 'Transportation'
);
insert testAccount;
System.debug('Created Account ID: ' + testAccount.Id);
```

#### **3.2 테스트용 Tasks/Events 생성**
```apex
// 테스트용 Task 생성
List<Task> testTasks = new List<Task>{
    new Task(
        Subject = '고객 미팅 준비',
        ActivityDate = Date.today(),
        Status = 'In Progress',
        Priority = 'High',
        WhatId = testAccount.Id
    ),
    new Task(
        Subject = '제안서 검토',
        ActivityDate = Date.today(),
        Status = 'Not Started',
        Priority = 'Normal'
    )
};
insert testTasks;
```

---

## 🚀 **권장 해결 순서 (30분 완성)**

### **단계 1: 서비스 직접 테스트 (10분)**
```bash
목표: 배포된 서비스들이 정상 작동하는지 확인
방법: Anonymous Apex 실행
```

### **단계 2: 샘플 데이터 생성 (10분)**
```bash
목표: Actions이 작동할 수 있는 실제 데이터 생성
방법: Account, Task, Event 생성
```

### **단계 3: Actions 재설정 (10분)**
```bash
목표: Record ID 의존성 제거
방법: Topic Actions 재구성
```

---

## 📋 **즉시 실행할 작업**

### **1. Anonymous Apex 실행 (지금 바로)**

**Developer Console → Execute Anonymous:**
```apex
// 1. 사용자 정보 확인
System.debug('Current User ID: ' + UserInfo.getUserId());
System.debug('Current User Name: ' + UserInfo.getName());

// 2. 기존 Tasks 확인
List<Task> userTasks = [SELECT Id, Subject, ActivityDate, Status 
                        FROM Task 
                        WHERE OwnerId = :UserInfo.getUserId() 
                        AND ActivityDate = TODAY];
System.debug('Found ' + userTasks.size() + ' tasks for today');

// 3. AgentforceSalesAssistantService 테스트
List<AgentforceSalesAssistantService.AgentforceRequest> requests = 
    new List<AgentforceSalesAssistantService.AgentforceRequest>();

AgentforceSalesAssistantService.AgentforceRequest request = 
    new AgentforceSalesAssistantService.AgentforceRequest();
request.requestType = 'getDailyBriefing';
request.userId = UserInfo.getUserId();
requests.add(request);

try {
    List<AgentforceSalesAssistantService.AgentforceResponse> responses = 
        AgentforceSalesAssistantService.processAgentforceRequests(requests);
    System.debug('SUCCESS: ' + responses[0].responseMessage);
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
```

### **2. 테스트 데이터 생성 (바로 이어서)**
```apex
// 테스트용 Account 및 Tasks 생성
Account testAccount = new Account(
    Name = 'SOCAR 테스트 B2B 고객',
    Type = 'Customer',
    Industry = 'Transportation'
);
insert testAccount;

List<Task> testTasks = new List<Task>{
    new Task(
        Subject = '오늘 고객 미팅',
        ActivityDate = Date.today(),
        Status = 'In Progress',
        Priority = 'High',
        WhatId = testAccount.Id,
        OwnerId = UserInfo.getUserId()
    ),
    new Task(
        Subject = '제안서 작성',
        ActivityDate = Date.today(),
        Status = 'Not Started',
        Priority = 'Normal',
        OwnerId = UserInfo.getUserId()
    )
};
insert testTasks;

System.debug('Created Account: ' + testAccount.Id);
System.debug('Created ' + testTasks.size() + ' tasks');
```

### **3. 다시 Agentforce 테스트**
```bash
Conversation에서 다시 입력:
"내 오늘 일정 보여줘"
```

---

## 🎯 **예상 결과**

### **성공 시나리오:**
```yaml
1. Anonymous Apex 실행 성공
   → AgentforceSalesAssistantService 정상 작동 확인

2. 테스트 데이터 생성 완료
   → 실제 Tasks/Account 데이터 존재

3. Agentforce 재테스트 성공
   → Topics이 실제 데이터와 연결되어 정상 응답
```

### **부분 성공 시나리오:**
```yaml
1. 서비스는 정상 작동하지만 Actions 연결 문제
   → Topics Actions 재설정 필요

2. 데이터는 생성되지만 권한 문제
   → Profile/Permission Sets 확인 필요
```

---

## 🔥 **핵심 포인트**

1. **시스템 자체는 완벽하게 작동 중** (Topic Selection, Action Selection 모두 정상)
2. **단순히 데이터 연결 문제** (샘플 Record ID vs 실제 데이터)
3. **30분 내 완전 해결 가능** (Anonymous Apex + 데이터 생성)

**지금 바로 Anonymous Apex를 실행해서 서비스 테스트를 시작하세요!** 🚀

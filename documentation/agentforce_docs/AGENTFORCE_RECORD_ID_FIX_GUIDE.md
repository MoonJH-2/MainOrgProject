# 🛠️ Agentforce Record ID 오류 해결 가이드

## 📍 현재 문제
- **오류**: `RECORD_NOT_FOUND. We couldn't find a record with the specified ID`
- **원인**: Actions에서 하드코딩된 샘플 Record ID 사용
- **해결**: 실제 Salesforce 레코드 ID로 테스트 필요

---

## 🎯 **즉시 해결 방법**

### **방법 1: 실제 Account ID로 테스트 (권장)** 🏆

#### **Step 1: Account 레코드 ID 확인**
```sql
-- SOQL Query로 실제 Account ID 확인
SELECT Id, Name, Type FROM Account LIMIT 5
```

#### **Step 2: 정확한 명령어로 다시 테스트**
```bash
# 현재 Conversation에서 다시 입력:
"Account ID 001XXXXXXXXX의 오늘 할 일 정리해줘"

# 또는 더 구체적으로:
"삼성전자 계정의 오늘 할 일 정리해줘"
```

---

### **방법 2: Topic별 개별 테스트** 🧪

#### **2.1 Sales Daily Management 테스트**
```bash
입력: "내 오늘 일정 보여줘"
예상: 개인 일정 및 태스크 조회 (User 기반)
```

#### **2.2 Customer Email Automation 테스트**
```bash
입력: "고객에게 일반적인 안내 이메일 작성해줘"
예상: 이메일 템플릿 생성 (Record ID 불필요)
```

#### **2.3 Customer Analysis 테스트**
```bash
입력: "전체 고객 이탈 위험도 분석해줘"
예상: 전체 고객 대상 분석 실행
```

#### **2.4 Team Collaboration 테스트**
```bash
입력: "팀에 일반 알림 보내줘"
예상: Chatter 팀 알림 발송
```

---

### **방법 3: 서비스 직접 호출 테스트** ⚡

#### **Anonymous Apex로 서비스 테스트:**
```apex
// AgentforceSalesAssistantService 직접 테스트
List<AgentforceSalesAssistantService.AgentforceRequest> requests = 
    new List<AgentforceSalesAssistantService.AgentforceRequest>();

AgentforceSalesAssistantService.AgentforceRequest request = 
    new AgentforceSalesAssistantService.AgentforceRequest();
request.requestType = 'getDailyBriefing';
request.userId = UserInfo.getUserId();
requests.add(request);

List<AgentforceSalesAssistantService.AgentforceResponse> responses = 
    AgentforceSalesAssistantService.processAgentforceRequests(requests);

System.debug('Response: ' + responses[0].responseMessage);
```

---

## 🎯 **현재 Conversation에서 즉시 실행할 테스트**

### **테스트 시나리오 1: 개인 일정 기반**
```bash
입력: "내 오늘 일정과 할 일 보여줘"
```

### **테스트 시나리오 2: 일반적인 업무**
```bash
입력: "오늘 해야 할 영업 업무가 뭐가 있나?"
```

### **테스트 시나리오 3: 구체적인 요청**
```bash
입력: "오늘 연락해야 할 고객이 있나?"
```

---

## 📊 **문제 분석 및 해결 우선순위**

### **우선순위 1: 즉시 해결 (5분)**
1. **현재 Conversation에서 Record ID 없는 테스트 실행**
2. **일반적인 명령어로 각 Topic 동작 확인**
3. **Topic Selection 정확성 검증**

### **우선순위 2: 데이터 확인 (10분)**
1. **SOQL로 실제 Account 레코드 확인**
2. **User Tasks 및 Events 데이터 존재 여부 확인**
3. **권한 설정 확인**

### **우선순위 3: 서비스 최적화 (15분)**
1. **Record ID 없을 때 기본 동작 개선**
2. **오류 처리 메시지 개선**
3. **Fallback 로직 추가**

---

## 🔍 **추가 디버깅 정보**

### **현재 확인된 정상 동작:**
- ✅ Topic Selection (0.29초)
- ✅ Action Selection (1.46초 + 0.49초)
- ✅ 4개 Topics 모두 생성됨
- ✅ 한국어 명령어 처리

### **확인 필요한 부분:**
- ❓ 실제 데이터 존재 여부
- ❓ Record ID 동적 처리 방식
- ❓ 권한 설정 적절성

---

## 🚀 **다음 즉시 실행할 작업**

### **1단계: 현재 Conversation에서 즉시 테스트**
```bash
화면 하단 입력창에 입력:
"내 오늘 일정 보여줘"
```

### **2단계: Topic별 순차 테스트**
```bash
1. "내 할 일 정리해줘" (개인 기반)
2. "고객에게 이메일 작성해줘" (일반적)
3. "고객 분석해줘" (전체 대상)
4. "팀에 알림 보내줘" (일반 알림)
```

### **3단계: 성공 시나리오 확인**
- 각 Topic이 정확히 선택되는지
- Actions이 정상 실행되는지
- 응답이 적절한지

---

## 🎉 **긍정적인 신호들**

1. **시스템이 살아있습니다!** Topics이 정확히 작동하고 있음
2. **우리가 만든 4개 Topics이 모두 정상 등록됨**
3. **Topic Selection 로직이 완벽하게 작동** (한국어 → 영어 Topic 매칭)
4. **Action Selection도 정상 진행됨**

**이제 Record ID 이슈만 해결하면 완전한 성공입니다!** 🚀

---

**즉시 실행: 현재 Conversation 화면에서 "내 오늘 일정 보여줘" 입력해보세요!** 🎯

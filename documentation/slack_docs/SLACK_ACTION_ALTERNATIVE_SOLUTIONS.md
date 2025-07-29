# 🛠️ Slack Channel Action 체크박스 해제 불가 - 대안 해결책

## ⚠️ **문제 상황 분석**

### **Standard Action 제약사항:**
```yaml
문제: "Require input"과 "Collect data from user" 체크 해제 불가
원인: Standard Salesforce Action의 내장 제약
타입: 시스템 레벨 제한사항
해결: 우회 방법 필요
```

---

## 🎯 **대안 해결책 1: Agent Instructions 수정**

### **현재 Instructions:**
```text
Create a Slack Channel. Ask the end user for a Channel name, the Team ID (or Workspace ID) to create the Slack Channel in and whether the Channel is public or private, unless these details are already provided.
```

### **수정된 Instructions:**
```text
Create a Slack Channel in the SOCAR workspace (Team ID: T094NAFCCSJ). Only ask the end user for a Channel name. Automatically use Team ID "T094NAFCCSJ" for the SOCAR workspace and set the channel as public by default. Do not ask for Team ID or workspace information.
```

### **수정 방법:**
```bash
1. Agent Action Instructions 필드 클릭
2. 기존 텍스트를 위의 수정된 텍스트로 교체
3. Save 클릭
```

---

## 🎯 **대안 해결책 2: SlackTeamID 변수에 기본값 설정**

### **Variables 설정 확인:**
```bash
경로 1: Setup → Custom Metadata Types → Agent Variables
경로 2: Agentforce Builder → Variables 탭

설정할 내용:
- Variable Name: SlackTeamID
- Default Value: T094NAFCCSJ
- Description: SOCAR Slack Workspace Team ID
```

### **변수 생성/수정 단계:**
```bash
1. Setup 메뉴에서 "Custom Metadata Types" 검색
2. "Agent Variable" 찾기
3. "Manage Records" 클릭
4. SlackTeamID 변수 찾아서 편집
5. Value 필드에 "T094NAFCCSJ" 입력
6. Save
```

---

## 🎯 **대안 해결책 3: Custom Simple Action 생성**

### **새로운 Custom Action 생성:**
```yaml
Action 이름: Create SOCAR Slack Channel
API 이름: CreateSOCARSlackChannel
타입: Apex Action (Custom)
목적: T094NAFCCSJ 하드코딩된 단순화 버전
```

### **Apex 코드 예시:**
```apex
public class CreateSOCARSlackChannelAction {
    
    @InvocableMethod(label='Create SOCAR Slack Channel')
    public static List<Result> createSlackChannel(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            // SOCAR Team ID 하드코딩
            String teamId = 'T094NAFCCSJ';
            String channelName = req.channelName;
            Boolean isPrivate = req.isPrivate != null ? req.isPrivate : false;
            
            // Slack API 호출 로직
            Result result = new Result();
            result.channelId = createChannel(teamId, channelName, isPrivate);
            result.channelUrl = 'https://socar.slack.com/channels/' + channelName;
            results.add(result);
        }
        
        return results;
    }
    
    public class Request {
        @InvocableVariable(required=true)
        public String channelName;
        
        @InvocableVariable
        public Boolean isPrivate;
    }
    
    public class Result {
        @InvocableVariable
        public String channelId;
        
        @InvocableVariable
        public String channelUrl;
    }
    
    private static String createChannel(String teamId, String channelName, Boolean isPrivate) {
        // Slack API 호출 구현
        return 'C' + String.valueOf(Math.random()).substring(2, 12);
    }
}
```

---

## 🎯 **대안 해결책 4: 워크플로우 수정**

### **사용자 경험 개선:**
```yaml
현재 문제: Team ID를 매번 물어봄
해결 아이디어: 사용자에게 명확한 가이드 제공

Agent Response 개선:
"Team ID는 자동으로 SOCAR 워크스페이스(T094NAFCCSJ)를 사용합니다. 
채널명만 알려주세요."
```

### **Instructions 최적화:**
```text
You are creating Slack channels specifically for the SOCAR team. When a user requests to create a Slack channel:

1. Ask ONLY for the channel name
2. Automatically use Team ID: T094NAFCCSJ (SOCAR workspace)
3. Set channel as public by default
4. Inform the user that you're using the SOCAR workspace automatically

Never ask for Team ID or Workspace ID as it's predefined for SOCAR.
```

---

## 🎯 **대안 해결책 5: Topic Instructions 수정**

### **Topic 레벨에서 제어:**
```bash
경로: Topics → SOCAR B2B Team Collaboration → Instructions

추가할 내용:
"For Slack channel creation, always use the SOCAR workspace (Team ID: T094NAFCCSJ). 
Only ask users for channel name and assume public channels unless specifically requested otherwise."
```

---

## 🚀 **즉시 실행 가능한 최적 해결책**

### **추천 순서:**

#### **1순위: Agent Instructions 수정 (가장 간단)**
```text
현재 Instructions를 다음으로 교체:

"Create a Slack Channel in the SOCAR workspace. Use Team ID 'T094NAFCCSJ' automatically. Only ask the user for the channel name. Create public channels by default unless the user specifically requests a private channel. Provide the channel URL and mention upon successful creation."
```

#### **2순위: SlackTeamID 변수 기본값 설정**
```bash
Variables에서 SlackTeamID에 T094NAFCCSJ 기본값 설정
```

#### **3순위: Topic Instructions 보강**
```text
Topic 레벨에서 Slack 관련 지침 추가
```

---

## 🔍 **테스트 시나리오**

### **수정 후 예상 동작:**
```bash
사용자: "프로젝트 채널 만들어줘"
Agent: "채널명을 알려주세요. SOCAR 워크스페이스에 자동으로 생성됩니다."
사용자: "project-alpha"
Agent: "T094NAFCCSJ 워크스페이스에 project-alpha 채널을 생성했습니다!"
```

---

## 💡 **결론 및 권장사항**

### **가장 효과적인 해결책:**
```yaml
1️⃣ Agent Instructions 수정 (즉시 적용 가능)
2️⃣ SlackTeamID 변수 기본값 설정 (보완)
3️⃣ 필요시 Custom Action 개발 (장기적)
```

### **즉시 실행:**
```bash
Agent Action Instructions 필드에서:
기존 텍스트 → 수정된 Instructions로 교체
→ Save → 테스트
```

**Standard Action의 제약을 우회하는 가장 효과적인 방법은 Instructions 수정입니다!** 🎯

**지금 바로 Agent Instructions를 수정해보세요!** 🚀

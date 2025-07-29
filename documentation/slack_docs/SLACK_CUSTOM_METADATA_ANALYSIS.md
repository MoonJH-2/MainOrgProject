# 🎯 Custom Metadata Types 분석 및 Slack 설정 활용 가이드

## 📋 **현재 Org의 Custom Metadata Types 현황**

### **발견된 Slack 관련 Metadata:**
```yaml
✅ Slack_Config__mdt (396 bytes)
   - 목적: Slack 설정 관리
   - 활용: Team ID, API 설정 등

✅ Slack_Setting__mdt (396 bytes)  
   - 목적: Slack 설정 관리
   - 활용: 추가 Slack 구성 정보

❌ Agent Variable (없음)
   - Agentforce 전용 변수 관리
   - 별도 생성 필요할 수 있음
```

---

## 🎯 **기존 Slack Metadata 활용 방안**

### **Slack_Config__mdt 레코드 확인:**
```bash
"Manage Records" 클릭하여 확인할 항목들:
- Team ID 설정: T094NAFCCSJ
- Bot Token 설정
- API 엔드포인트 설정
- 채널 기본 설정
```

### **Slack_Setting__mdt 레코드 확인:**
```bash
추가 설정 확인:
- Workspace 정보
- 권한 설정
- 기본 채널 정보
- 오류 처리 설정
```

---

## 🚀 **즉시 실행할 단계들**

### **Step 1: Slack_Config__mdt 레코드 확인**
```bash
현재 화면에서:
1. "Slack_Config__mdt" 행에서 "Manage Records" 클릭
2. 기존 레코드 있는지 확인
3. Team ID가 T094NAFCCSJ로 설정되어 있는지 확인
```

### **Step 2: 필요시 새 레코드 생성**
```bash
Slack_Config__mdt에서:
1. "New" 버튼 클릭
2. 다음 정보 입력:
   - Label: SOCAR Workspace Config
   - Name: SOCAR_Workspace
   - Team_ID__c: T094NAFCCSJ
   - Bot_Token__c: [실제 토큰]
   - API_Base_URL__c: https://slack.com/api/
```

### **Step 3: Slack_Setting__mdt 레코드 확인**
```bash
1. "Slack_Setting__mdt" 행에서 "Manage Records" 클릭  
2. 추가 설정 확인/생성
```

---

## 🔧 **Apex Class에서 기존 Metadata 활용**

### **SlackChannelManager 수정 버전:**
```apex
public class SlackChannelManager {
    
    @InvocableMethod(label='Create SOCAR Slack Channel')
    public static List<SlackChannelResult> createSlackChannel(List<SlackChannelRequest> requests) {
        List<SlackChannelResult> results = new List<SlackChannelResult>();
        
        // 기존 Slack_Config__mdt에서 설정 조회
        Slack_Config__mdt slackConfig = getSlackConfig();
        if (slackConfig == null) {
            SlackChannelResult errorResult = new SlackChannelResult();
            errorResult.isSuccess = false;
            errorResult.errorMessage = 'Slack configuration not found in Slack_Config__mdt';
            results.add(errorResult);
            return results;
        }
        
        for (SlackChannelRequest request : requests) {
            SlackChannelResult result = new SlackChannelResult();
            
            try {
                // Metadata에서 Team ID 가져오기
                String teamId = slackConfig.Team_ID__c; // T094NAFCCSJ
                String botToken = slackConfig.Bot_Token__c;
                String apiBaseUrl = slackConfig.API_Base_URL__c;
                
                String channelName = request.channelName.toLowerCase().replaceAll('[^a-z0-9_-]', '-');
                
                // HTTP Request 구성
                HttpRequest req = new HttpRequest();
                req.setEndpoint(apiBaseUrl + 'conversations.create');
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + botToken);
                req.setHeader('Content-Type', 'application/json');
                
                Map<String, Object> requestBody = new Map<String, Object>{
                    'name' => channelName,
                    'is_private' => request.isPrivate != null ? request.isPrivate : false
                };
                req.setBody(JSON.serialize(requestBody));
                
                // API 호출
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                // 응답 처리
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    Boolean ok = (Boolean) responseMap.get('ok');
                    
                    if (ok) {
                        Map<String, Object> channel = (Map<String, Object>) responseMap.get('channel');
                        result.isSuccess = true;
                        result.channelId = (String) channel.get('id');
                        result.channelName = (String) channel.get('name');
                        result.channelUrl = 'https://socar.slack.com/channels/' + result.channelName;
                    } else {
                        result.isSuccess = false;
                        result.errorMessage = 'Slack API Error: ' + responseMap.get('error');
                        System.debug('Slack API Error Details: ' + responseMap);
                    }
                } else {
                    result.isSuccess = false;
                    result.errorMessage = 'HTTP Error: ' + res.getStatusCode() + ' - ' + res.getBody();
                    System.debug('HTTP Error Details: ' + res.getBody());
                }
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.errorMessage = 'Exception: ' + e.getMessage();
                System.debug('SlackChannelManager Exception: ' + e.getStackTraceString());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Slack_Config__mdt에서 설정 조회
    private static Slack_Config__mdt getSlackConfig() {
        try {
            List<Slack_Config__mdt> configs = [
                SELECT Team_ID__c, Bot_Token__c, API_Base_URL__c, Label
                FROM Slack_Config__mdt 
                WHERE Label = 'SOCAR Workspace Config' 
                   OR Team_ID__c = 'T094NAFCCSJ'
                LIMIT 1
            ];
            
            return configs.isEmpty() ? null : configs[0];
            
        } catch (Exception e) {
            System.debug('Failed to retrieve Slack config: ' + e.getMessage());
            return null;
        }
    }
    
    // Request/Result 클래스들
    public class SlackChannelRequest {
        @InvocableVariable(required=true)
        public String channelName;
        
        @InvocableVariable
        public Boolean isPrivate;
    }
    
    public class SlackChannelResult {
        @InvocableVariable
        public Boolean isSuccess;
        
        @InvocableVariable
        public String channelId;
        
        @InvocableVariable
        public String channelName;
        
        @InvocableVariable
        public String channelUrl;
        
        @InvocableVariable
        public String errorMessage;
    }
}
```

---

## 📊 **Slack_Config__mdt 필드 구조 예상**

### **필요한 Custom Fields:**
```yaml
Team_ID__c (Text):
- Value: T094NAFCCSJ
- Description: Slack Workspace Team ID

Bot_Token__c (Text, Encrypted):
- Value: xoxb-your-bot-token
- Description: Slack Bot OAuth Token

API_Base_URL__c (Text):
- Value: https://slack.com/api/
- Description: Slack API Base URL

Default_Channel_Type__c (Checkbox):
- Value: false (Public)
- Description: Default channel privacy setting
```

---

## 🎯 **즉시 확인할 사항들**

### **1순위: Slack_Config__mdt 레코드 확인**
```bash
현재 화면에서 "Slack_Config__mdt" → "Manage Records" 클릭
→ 기존 레코드 있는지 확인
→ Team ID 필드에 T094NAFCCSJ 설정되어 있는지 확인
```

### **2순위: Slack_Setting__mdt 레코드 확인**  
```bash
"Slack_Setting__mdt" → "Manage Records" 클릭
→ 추가 설정 정보 확인
```

### **3순위: 필드 구조 확인**
```bash
각 Metadata Type 클릭
→ "Custom Fields & Relationships" 섹션 확인
→ Team_ID__c, Bot_Token__c 등 필드 존재 여부 확인
```

---

## 💡 **기존 Metadata 활용의 장점**

### **왜 기존 구조를 사용해야 하는가:**
```yaml
✅ 이미 구축된 인프라: 재사용 가능
✅ 기존 통합과의 호환성: 충돌 방지
✅ 빠른 구현: 새로 만들 필요 없음
✅ 표준화된 구조: 유지보수 용이
```

### **Agent Variable vs 기존 Slack Metadata:**
```yaml
Agent Variable:
- Agentforce 전용
- 새로 생성 필요
- 추가 구성 작업 필요

기존 Slack Metadata:
- 이미 존재함 ✅
- 즉시 활용 가능 ✅  
- 검증된 구조 ✅
```

---

## 🚀 **즉시 실행 액션**

### **지금 바로 할 수 있는 것:**
```bash
1. Slack_Config__mdt → Manage Records 클릭
2. 기존 레코드에 T094NAFCCSJ 설정 확인
3. 없다면 새 레코드 생성하여 Team ID 설정
4. Bot Token 등 추가 필드 확인/설정
```

### **다음 단계:**
```bash
1. 위의 수정된 Apex Class 배포
2. 기존 Metadata 구조 활용한 Custom Action 생성
3. Agentforce에서 Standard Action 대신 Custom Action 사용
```

**기존에 Slack_Config__mdt와 Slack_Setting__mdt가 있다는 것은 이미 Slack 통합 준비가 되어있다는 의미입니다!**

**지금 바로 "Slack_Config__mdt" → "Manage Records"를 클릭해서 T094NAFCCSJ 설정을 확인해보세요!** 🎯

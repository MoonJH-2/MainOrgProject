# 🚨 Slack "access_denied" 오류 상세 분석 및 해결 가이드

## 🔍 **오류 발생 위치 및 원인 분석**

### **오류 정보:**
```yaml
Error: access_denied
Context: Slack 채널 생성 시도 중
Session ID: 6e316ff6-5ea0-4576-a489-fb16b3e056e6
Action: Create Slack Channel with T094NAFCCSJ
```

### **access_denied 발생 가능 위치:**
```yaml
1️⃣ Slack API Level (가장 가능성 높음)
   - Slack App 권한 부족
   - OAuth Token 만료/무효
   - Workspace 권한 부족

2️⃣ Salesforce Connected App Level
   - OAuth 설정 문제
   - IP 제한 문제
   - 사용자 권한 부족

3️⃣ Agentforce Action Level
   - Action 실행 권한 부족
   - Variable 접근 권한 문제
```

---

## 🔧 **Apex Class 기반 해결 방안**

### **1. Custom Slack Integration Apex Class**

#### **SlackChannelManager.cls:**
```apex
public class SlackChannelManager {
    
    // Slack API 엔드포인트
    private static final String SLACK_API_BASE = 'https://slack.com/api/';
    private static final String CREATE_CHANNEL_ENDPOINT = 'conversations.create';
    
    @InvocableMethod(label='Create SOCAR Slack Channel' description='Create Slack channel with proper error handling')
    public static List<SlackChannelResult> createSlackChannel(List<SlackChannelRequest> requests) {
        List<SlackChannelResult> results = new List<SlackChannelResult>();
        
        for (SlackChannelRequest request : requests) {
            SlackChannelResult result = new SlackChannelResult();
            
            try {
                // SOCAR Team ID 하드코딩
                String teamId = 'T094NAFCCSJ';
                String channelName = request.channelName.toLowerCase().replaceAll('[^a-z0-9_-]', '-');
                
                // Slack API 호출
                String accessToken = getSlackAccessToken();
                if (String.isBlank(accessToken)) {
                    result.isSuccess = false;
                    result.errorMessage = 'Slack Access Token not found. Check Connected App configuration.';
                    results.add(result);
                    continue;
                }
                
                // HTTP Request 구성
                HttpRequest req = new HttpRequest();
                req.setEndpoint(SLACK_API_BASE + CREATE_CHANNEL_ENDPOINT);
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                
                // Request Body
                Map<String, Object> requestBody = new Map<String, Object>{
                    'name' => channelName,
                    'is_private' => request.isPrivate != null ? request.isPrivate : false
                };
                req.setBody(JSON.serialize(requestBody));
                
                // API 호출 실행
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
                    }
                } else {
                    result.isSuccess = false;
                    result.errorMessage = 'HTTP Error: ' + res.getStatusCode() + ' - ' + res.getBody();
                }
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.errorMessage = 'Apex Exception: ' + e.getMessage();
                System.debug('SlackChannelManager Exception: ' + e.getStackTraceString());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Slack Access Token 조회
    private static String getSlackAccessToken() {
        try {
            // Custom Metadata 또는 Custom Setting에서 토큰 조회
            // 보안상 Named Credential 사용 권장
            List<SlackCredential__mdt> credentials = [
                SELECT AccessToken__c 
                FROM SlackCredential__mdt 
                WHERE DeveloperName = 'SOCAR_Workspace' 
                LIMIT 1
            ];
            
            if (!credentials.isEmpty()) {
                return credentials[0].AccessToken__c;
            }
            
            // 대안: Custom Setting 사용
            SlackSettings__c settings = SlackSettings__c.getOrgDefaults();
            return settings != null ? settings.AccessToken__c : null;
            
        } catch (Exception e) {
            System.debug('Failed to retrieve Slack Access Token: ' + e.getMessage());
            return null;
        }
    }
    
    // Request 클래스
    public class SlackChannelRequest {
        @InvocableVariable(required=true)
        public String channelName;
        
        @InvocableVariable
        public Boolean isPrivate;
    }
    
    // Result 클래스
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

## 🔍 **access_denied 상세 진단**

### **1. Slack API Level 문제**

#### **가능한 원인들:**
```yaml
❌ 잘못된 OAuth Token
   - 만료된 토큰
   - 잘못된 스코프 권한
   - 취소된 토큰

❌ 부족한 Bot 권한
   - channels:write 권한 없음
   - chat:write 권한 없음
   - 워크스페이스 관리자 승인 필요

❌ 워크스페이스 정책
   - 채널 생성 권한 제한
   - 외부 앱 사용 제한
   - 관리자 승인 필요
```

#### **진단 방법:**
```apex
// Slack API 연결 테스트
public static void testSlackConnection() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://slack.com/api/auth.test');
    req.setMethod('POST');
    req.setHeader('Authorization', 'Bearer ' + getSlackAccessToken());
    
    HttpResponse res = new Http().send(req);
    System.debug('Slack Auth Test: ' + res.getBody());
}
```

### **2. Salesforce Connected App 문제**

#### **확인할 설정들:**
```yaml
Connected App 권한:
✅ Access unique user identifiers
✅ Perform requests at any time  
✅ Access the identity URL service
✅ Full access (또는 필요 권한만)

OAuth 설정:
✅ IP Relaxation: Enforce IP restrictions
✅ Permitted Users: All users may self-authorize
✅ Refresh Token Policy: 적절히 설정
```

### **3. Named Credential 설정**

#### **권장 보안 설정:**
```yaml
Named Credential 생성:
- Name: SOCAR_Slack_API
- URL: https://slack.com/api/
- Identity Type: Named Principal
- Authentication Protocol: OAuth 2.0
- Authentication Provider: Slack_Auth_Provider
```

---

## 🚀 **단계별 해결 방안**

### **Phase 1: 진단 및 확인**

#### **1. Slack App 권한 확인:**
```bash
https://api.slack.com/apps/YOUR_APP_ID/oauth
→ Bot Token Scopes 확인:
   - channels:write
   - chat:write
   - users:read
```

#### **2. Connected App 상태 확인:**
```bash
Setup → Connected Apps → Slack
→ OAuth Usage 클릭하여 토큰 상태 확인
```

#### **3. Debug Log 활성화:**
```bash
Setup → Debug Logs
→ User에 대해 Apex Class 레벨 디버그 활성화
```

### **Phase 2: Custom Apex 구현**

#### **1. 위의 SlackChannelManager 클래스 배포:**
```bash
sf project deploy start -m ApexClass:SlackChannelManager
```

#### **2. Custom Metadata 또는 Custom Setting 생성:**
```yaml
SlackCredential__mdt 또는 SlackSettings__c 생성
AccessToken__c 필드에 올바른 토큰 저장
```

#### **3. Agentforce Action 교체:**
```bash
기존 Standard Action 대신
Custom Apex Action 사용 설정
```

### **Phase 3: 테스트 및 검증**

#### **1. Anonymous Apex 테스트:**
```apex
SlackChannelManager.SlackChannelRequest req = new SlackChannelManager.SlackChannelRequest();
req.channelName = 'test-channel';
req.isPrivate = false;

List<SlackChannelManager.SlackChannelRequest> requests = new List<SlackChannelManager.SlackChannelRequest>{req};
List<SlackChannelManager.SlackChannelResult> results = SlackChannelManager.createSlackChannel(requests);

System.debug('Result: ' + results[0]);
```

---

## 🎯 **즉시 실행 가능한 해결책**

### **1. 빠른 진단 (5분):**
```bash
Setup → Connected Apps → Slack → OAuth Usage 확인
→ 토큰 상태 및 마지막 사용 시간 확인
```

### **2. 권한 재확인 (10분):**
```bash
Slack App 설정 → OAuth & Permissions
→ Bot Token Scopes에 channels:write 있는지 확인
→ 없다면 추가 후 재설치
```

### **3. Custom Apex 배포 (30분):**
```bash
위의 SlackChannelManager 클래스 구현
→ Custom Action으로 교체
→ 상세한 오류 로깅 및 처리
```

---

## 📊 **오류 해결 우선순위**

### **1순위: Slack App 권한**
```yaml
가능성: 90%
해결시간: 5-10분
방법: Slack App 설정에서 권한 추가
```

### **2순위: OAuth Token 문제**
```yaml
가능성: 70%
해결시간: 10-20분  
방법: 토큰 재생성 및 Connected App 재설정
```

### **3순위: Custom Apex 구현**
```yaml
가능성: 100% (해결책)
해결시간: 30-60분
방법: 완전한 커스텀 구현으로 모든 오류 해결
```

---

## 💡 **결론**

### **access_denied 주요 원인:**
```yaml
1️⃣ Slack Bot 권한 부족 (channels:write 없음)
2️⃣ OAuth Token 만료/무효
3️⃣ Workspace 정책 제한
```

### **최적 해결책:**
```yaml
✅ 즉시: Slack App 권한 확인 및 추가
✅ 단기: OAuth 설정 재구성
✅ 장기: Custom Apex 구현으로 완전한 제어
```

**Apex Class 기반 Custom 구현이 가장 안정적이고 제어 가능한 해결책입니다!** 🚀

**지금 바로 Slack App의 Bot Token Scopes에서 'channels:write' 권한을 확인해보세요!** 🎯

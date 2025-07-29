# 🛠️ Salesforce Setup - Slack 문제 해결 상세 가이드

## 🎯 **Setup에서 확인해야 할 정확한 경로들**

### **1단계: Connected Apps 확인**

#### **경로:**
```bash
Setup (⚙️ 아이콘) 클릭
→ Quick Find 박스에 "Connected Apps" 입력
→ "Connected Apps" 선택
→ "Manage Connected Apps" 클릭
→ 목록에서 "Slack" 찾아서 클릭
```

#### **확인할 항목들:**
```yaml
✅ Basic Information:
   - App Name: Slack
   - Version: 최신 버전 확인
   - Status: Active 상태인지 확인

✅ OAuth Policies:
   - Permitted Users: "All users may self-authorize" 또는 적절한 설정
   - IP Relaxation: "Enforce IP restrictions" 또는 "Relax IP restrictions"
   - Refresh Token Policy: "Refresh token is valid until revoked"

✅ Application Permissions:
   - "Full access" 또는 다음 권한들:
     ✓ Access unique user identifiers
     ✓ Perform requests at any time
     ✓ Access the identity URL service
     ✓ Access Connect REST API resources
     ✓ Access Lightning applications
```

#### **OAuth Usage 확인:**
```bash
Connected App 세부 정보에서
→ "View" 버튼 옆의 ▼ 클릭
→ "OAuth Usage" 선택
→ 최근 토큰 사용 현황 및 오류 확인
```

---

### **2단계: Named Credentials 확인**

#### **경로:**
```bash
Setup → Quick Find에 "Named Credentials" 입력
→ "Named Credentials" 선택
→ 목록에서 Slack 관련 Credential 찾기
```

#### **확인할 항목들:**
```yaml
Named Credential 설정:
- Name: Slack_API 또는 유사한 이름
- URL: https://slack.com/api/
- Identity Type: "Named Principal" 또는 "Per User"
- Authentication Protocol: "OAuth 2.0"
- Generate Authorization Header: ✅ 체크됨
- Allow Merge Fields in HTTP Header: ✅ 체크됨
- Allow Merge Fields in HTTP Body: ✅ 체크됨
```

#### **생성이 필요한 경우:**
```bash
"New" 버튼 클릭
→ Named Credential 정보 입력:
   - Label: SOCAR Slack API
   - Name: SOCAR_Slack_API
   - URL: https://slack.com/api/
   - Identity Type: Named Principal
   - Authentication Protocol: OAuth 2.0
```

---

### **3단계: Custom Metadata Types 확인**

#### **경로:**
```bash
Setup → Quick Find에 "Custom Metadata Types" 입력
→ "Custom Metadata Types" 선택
→ "Agent Variable" 찾아서 클릭
→ "Manage Records" 클릭
```

#### **확인할 Variables:**
```yaml
SlackTeamID Variable:
- Label: SlackTeamID
- Name: SlackTeamID
- Value: T094NAFCCSJ
- Description: SOCAR Slack Workspace Team ID

추가 생성이 필요한 Variables:
- SlackBotToken (보안상 권장하지 않음)
- SlackChannelPrefix (채널명 접두사)
```

---

### **4단계: External Services 확인**

#### **경로:**
```bash
Setup → Quick Find에 "External Services" 입력
→ "External Services" 선택
→ Slack 관련 서비스 확인
```

#### **Slack API Schema 등록:**
```yaml
필요시 새 External Service 생성:
- Service Name: Slack_API
- Schema Type: OpenAPI 3.0
- Schema Source: Slack API 스키마 파일
```

---

### **5단계: Remote Site Settings 확인**

#### **경로:**
```bash
Setup → Quick Find에 "Remote Site Settings" 입력
→ "Remote Site Settings" 선택
→ Slack 관련 사이트 확인
```

#### **필요한 Remote Sites:**
```yaml
✅ https://slack.com
   - Remote Site Name: Slack_API
   - Remote Site URL: https://slack.com
   - Active: ✅ 체크됨

✅ https://hooks.slack.com (Webhook용)
   - Remote Site Name: Slack_Webhooks
   - Remote Site URL: https://hooks.slack.com  
   - Active: ✅ 체크됨
```

---

### **6단계: Auth Providers 확인**

#### **경로:**
```bash
Setup → Quick Find에 "Auth. Providers" 입력
→ "Auth. Providers" 선택
→ Slack 관련 Provider 확인
```

#### **Slack Auth Provider 설정:**
```yaml
Provider Type: Slack
Name: Slack_OAuth
URL Suffix: slack
Consumer Key: [Slack App Client ID]
Consumer Secret: [Slack App Client Secret]
Authorize Endpoint URL: https://slack.com/oauth/v2/authorize
Token Endpoint URL: https://slack.com/api/oauth.v2.access
User Info Endpoint URL: https://slack.com/api/auth.test
```

---

### **7단계: Debug Logs 설정**

#### **경로:**
```bash
Setup → Quick Find에 "Debug Logs" 입력
→ "Debug Logs" 선택
→ "New" 클릭하여 현재 사용자 추가
```

#### **Debug 설정:**
```yaml
Traced Entity Type: User
Traced Entity: [현재 사용자]
Debug Level:
- Apex Code: DEBUG
- Apex Profiling: INFO  
- Callout: DEBUG
- Database: INFO
- System: DEBUG
- Validation: INFO
- Visualforce: INFO
- Workflow: INFO
```

---

### **8단계: Agentforce Builder 설정 재확인**

#### **경로:**
```bash
Setup → Quick Find에 "Agentforce" 입력
→ "Agentforce" 선택  
→ "SOCAR Sales Agent" 클릭
→ "Version 3" 선택
→ "Topics" 탭 클릭
→ "SOCAR B2B Team Collaboration" 클릭
→ Actions 섹션에서 "Create a Slack Channel" 클릭
```

#### **Action 설정 재확인:**
```yaml
Agent Action Instructions:
"Create a Slack Channel in the SOCAR workspace (T094NAFCCSJ). 
Only ask for channel name. Use Team ID T094NAFCCSJ automatically."

Team ID 필드:
- Assign a Variable: SlackTeamID ✅
- Require input: ❌ (해제 시도)
- Collect data from user: ❌ (해제 시도)
```

---

## 🚨 **즉시 확인해야 할 우선순위 항목들**

### **1순위: Connected Apps OAuth Usage**
```bash
Setup → Connected Apps → Slack → OAuth Usage
→ 마지막 토큰 사용 시간 확인
→ 오류 메시지 있는지 확인
→ 토큰 상태 Active인지 확인
```

### **2순위: Remote Site Settings**
```bash
Setup → Remote Site Settings
→ https://slack.com 사이트 등록 여부 확인
→ Active 상태인지 확인
→ 없다면 즉시 추가
```

### **3순위: Debug Logs 활성화**
```bash
Setup → Debug Logs → New
→ 현재 사용자 추가
→ Apex Code와 Callout을 DEBUG 레벨로 설정
→ Agentforce 테스트 후 로그 확인
```

---

## 🔧 **Custom Apex 배포를 위한 Setup 설정**

### **Apex Classes 경로:**
```bash
Setup → Quick Find에 "Apex Classes" 입력
→ "Apex Classes" 선택
→ "New" 클릭하여 SlackChannelManager 클래스 생성
```

### **Flow Builder에서 Apex Action 등록:**
```bash
Setup → Quick Find에 "Flows" 입력
→ "Flows" 선택
→ 새 Flow 생성하여 Apex Action 테스트
```

---

## 🎯 **문제 해결 체크리스트**

### **즉시 확인할 Setup 항목들:**
```yaml
□ Connected Apps → Slack → OAuth Usage 확인
□ Remote Site Settings → https://slack.com 등록 확인
□ Named Credentials → Slack API 설정 확인
□ Custom Metadata Types → SlackTeamID 변수 확인
□ Debug Logs → 현재 사용자 Debug 활성화
□ Auth Providers → Slack OAuth 설정 확인
```

### **문제 발견시 수정 사항:**
```yaml
❌ OAuth 토큰 만료 → Connected App에서 재인증
❌ Remote Site 없음 → https://slack.com 추가
❌ Named Credential 없음 → 새로 생성
❌ SlackTeamID 변수 없음 → T094NAFCCSJ 값으로 생성
❌ Debug Log 없음 → 활성화하여 상세 오류 확인
```

---

## 🚀 **즉시 실행 액션**

### **5분 내 확인 가능:**
```bash
1. Setup → Connected Apps → Slack → OAuth Usage 확인
2. Setup → Remote Site Settings → https://slack.com 확인
3. Setup → Debug Logs → 사용자 Debug 활성화
```

### **15분 내 수정 가능:**
```bash
1. 누락된 Remote Site 추가
2. SlackTeamID 변수 생성/수정
3. Named Credential 생성 (필요시)
```

### **30분 내 완전 해결:**
```bash
1. Custom Apex Class 배포
2. Agentforce Action을 Custom으로 교체
3. 전체 시스템 테스트 및 검증
```

**지금 바로 Setup → Connected Apps → Slack → OAuth Usage를 확인해서 토큰 상태부터 확인해보세요!** 🎯

**대부분의 경우 Remote Site Settings에 https://slack.com이 등록되지 않아서 발생하는 문제입니다!** 🚀

# Agentforce Experience Cloud 연동 및 Service Channel 오류 해결 가이드

## 📋 목차
- [1. Experience Cloud Agentforce 연동 문제 해결](#1-experience-cloud-agentforce-연동-문제-해결)
- [2. Service Channel 오류 해결](#2-service-channel-오류-해결)
- [3. 일반적인 문제 해결](#3-일반적인-문제-해결)

---

## 1. Experience Cloud Agentforce 연동 문제 해결

### 🔍 **문제 상황**
- Experience Cloud에서 다른 기능은 작동하지만 Agentforce만 작동하지 않음
- Agentforce가 화면에 표시되지 않음

### 📋 **1단계: Agentforce 라이센스 및 기능 활성화 확인**

#### ✅ **조직 차원 Agentforce 활성화**
```bash
Setup → Company Information → Organization Information
→ Features → "Agentforce" 체크박스 활성화 확인
```

#### ✅ **Agentforce 라이센스 할당**
```bash
Setup → Users → Permission Sets
→ "Agentforce User" Permission Set이 Experience Cloud 사용자에게 할당되었는지 확인
```

#### ✅ **Experience Cloud용 Agentforce 설정**
```bash
Setup → Feature Settings → Service → Agentforce
→ "Enable Agentforce in Digital Experiences" 체크박스 활성화
```

### 📋 **2단계: Agentforce Agent 배포 상태 상세 확인**

#### ✅ **Agent 배포 채널 설정**
```bash
Agentforce Studio → Agents → [Your Service Agent]
→ Channels 탭 → "Digital Experience" 채널 추가 및 활성화
```

#### ✅ **Agent Topic 및 Actions 확인**
```javascript
// Agent가 응답할 수 있는 Topic이 설정되어 있는지 확인
Agentforce Studio → Agents → [Agent] → Topics
// 최소 1개 이상의 Active Topic 필요
```

#### ✅ **Agent Test 실행**
```bash
Agentforce Studio → Agents → [Agent] → Test
→ "Hello" 메시지로 응답 테스트
→ 정상 응답 확인 후 Experience Cloud 테스트 진행
```

### 📋 **3단계: Experience Cloud 사이트별 Agentforce 설정**

#### ✅ **사이트 레벨 Agentforce 활성화**
```bash
Experience Cloud → All Sites → [Site Name] → Administration
→ Settings → General → Advanced → "Enable Agentforce" 체크
```

#### ✅ **Digital Experience 메타데이터 확인**
```xml
<!-- Experience Cloud Site의 메타데이터에서 확인 -->
<customMetadata>
    <agentforceEnabled>true</agentforceEnabled>
    <serviceChatEnabled>true</serviceChatEnabled>
</customMetadata>
```

### 📋 **4단계: Chat 컴포넌트 Agentforce 연동 설정**

#### ✅ **올바른 Chat 컴포넌트 사용**
```javascript
// Experience Builder에서
Components → Search "Service Chat" (일반 Chat이 아닌 Service Chat 사용)
// 또는
Components → "Einstein Chat" 컴포넌트 사용
```

#### ✅ **컴포넌트 속성 정확한 설정**
```json
{
  "chatConfiguration": {
    "agentId": "실제_Agent_ID",
    "enableAgentforce": true,
    "fallbackToLiveAgent": false,
    "agentforceOnly": true
  }
}
```

### 📋 **5단계: Guest User Profile Agentforce 권한 설정**

#### ✅ **Agentforce 전용 권한 부여**
```bash
Setup → Users → Profiles → [Site Guest User Profile]
→ System Permissions → "Use Agentforce" 체크
→ Object Settings → "AgentWork" Read 권한
→ Object Settings → "MessagingSession" Read, Create 권한
→ Object Settings → "ConversationEntry" Read, Create 권한
```

#### ✅ **API 권한 확인**
```bash
Guest User Profile → App Permissions
→ "Connected App Access" → Agentforce 관련 연결된 앱 권한 확인
```

### 📋 **6단계: 네트워크 및 보안 설정**

#### ✅ **Agentforce 전용 CORS 설정**
```bash
Setup → Security → CORS
→ New CORS Whitlist Entry
→ Origin URL Pattern: https://[your-experience-cloud-domain].force.com
→ Include Agentforce endpoints
```

#### ✅ **CSP Agentforce 도메인 추가**
```bash
Setup → Security → Content Security Policy → Trusted Sites
→ Add: *.salesforce.com (Agentforce API 도메인)
→ Add: *.force.com (Experience Cloud 도메인)
```

### 🔧 **즉시 해결 체크리스트**

**30초 내 확인 사항:**
- [ ] Agentforce Studio에서 Agent Status = Active
- [ ] Agent Channels에 "Digital Experience" 추가됨
- [ ] Experience Cloud Site에서 "Enable Agentforce" 체크됨
- [ ] Guest User Profile에 "Use Agentforce" 권한 있음

---

## 2. Service Channel 오류 해결

### 🔍 **오류 상황**
```bash
Error: The Service Channel ID 0N9gK000000emPJSAY isn't valid for this record type.
```

### 📋 **오류 분석**
- **핵심 문제**: Messaging Service Channel이 현재 Record Type(User Record)에 대해 유효하지 않음
- **원인**: Service Channel과 Record Type 간의 불일치

### 📋 **1단계: Service Channel 설정 확인**

#### ✅ **현재 Service Channel 정보 확인**
```bash
Setup → Service Setup → Channels → Messaging
→ Service Channel ID: 0N9gK000000emPJSAY 찾기
→ "Supported Objects" 섹션 확인
```

#### ✅ **지원되는 객체 타입 확인**
```bash
Service Channel 설정에서:
- Work Type Settings
- Supported Record Types
- Object Permissions 확인
```

### 📋 **2단계: Record Type 호환성 수정**

#### ✅ **User 객체용 Service Channel 설정**
```bash
Setup → Service Setup → Channels → Messaging
→ Edit → Supported Objects
→ "User" 객체 추가 (현재 누락되어 있음)
→ Save
```

#### ✅ **Work Type 설정 수정**
```bash
Setup → Service Setup → Work Types
→ Messaging 관련 Work Type 편집
→ "Supported Objects" → User 추가
→ Record Type 매핑 확인
```

### 📋 **3단계: Omni-Channel Flow 수정**

#### ✅ **Flow에서 Service Channel 로직 수정**
```javascript
// Flow Builder에서 "Get Common Status Omni Channel Flow" 편집
Flow Builder → Flows → "Get Common Status Omni Channel Flow"
→ ROUTE WORK 요소 편집
```

#### ✅ **조건부 Service Channel 선택 로직 추가**
```yaml
# Flow에서 Decision 요소 추가
IF recordId starts with "005" (User)
  THEN serviceChannelId = "User용_Service_Channel_ID"
ELSE IF recordId starts with "003" (Contact)  
  THEN serviceChannelId = "Contact용_Service_Channel_ID"
ELSE
  THEN serviceChannelId = "Default_Service_Channel_ID"
```

### 📋 **4단계: Agentforce 전용 Service Channel 생성**

#### ✅ **새 Service Channel 생성**
```bash
Setup → Service Setup → Channels → New
→ Channel Type: Messaging
→ Name: "Agentforce User Channel"
→ Supported Objects: User, Contact, Case 등 추가
→ Save
```

#### ✅ **Flow에서 새 Channel ID 사용**
```javascript
// Flow의 ROUTE WORK 요소에서
serviceChannelId = "새로_생성한_Channel_ID"
```

### 📋 **5단계: Queue 및 Routing 설정 검증**

#### ✅ **Queue 설정 확인**
```bash
Setup → Users → Queues → "Messaging Queue" (00GgK000003NoyWUAS)
→ Supported Objects에 User 객체 포함 확인
→ Queue Members 확인
```

#### ✅ **Routing Configuration 수정**
```bash
Setup → Service Setup → Omni-Channel Settings
→ Routing Configurations
→ Agentforce/Copilot 라우팅 설정 확인
```

### 📋 **6단계: Agentforce Agent 설정 수정**

#### ✅ **Copilot 설정 확인**
```bash
Agentforce Builder → "커몬 에이전트" (0XxgK000000QT3BSAW)
→ Channels 탭 → Service Channel 매핑 확인
→ 올바른 Service Channel 연결
```

#### ✅ **Agent Routing 설정**
```bash
Agent 설정 → Routing
→ Service Channel: 새로 생성한 Channel 선택
→ Queue: Messaging Queue 연결 확인
```

### 🚨 **즉시 해결 방법 (Quick Fix)**

**가장 빠른 해결책:**

1. **새 Service Channel 생성**
```bash
Setup → Service Channels → New
→ Name: "Universal Messaging Channel"
→ Supported Objects: User, Contact, Case, Lead 모두 추가
```

2. **Flow에서 Service Channel ID 변경**
```bash
Flow Builder → ROUTE WORK → serviceChannelId 필드
→ 새로 생성한 Channel ID로 변경
```

3. **Flow 저장 및 활성화**
```bash
Save → Activate → 새 버전으로 배포
```

---

## 3. 일반적인 문제 해결

### 🚨 **Agentforce 전용 일반적인 문제들**

#### **문제 1: Agent가 Digital Experience 채널에 배포되지 않음**
```bash
해결: Agentforce Studio → Channels → Digital Experience 추가
```

#### **문제 2: Guest User Profile에 Agentforce 권한 없음**
```bash
해결: Profile → System Permissions → "Use Agentforce" 활성화
```

#### **문제 3: Experience Cloud 사이트에서 Agentforce 기능 비활성화**
```bash
해결: Site Administration → Settings → Enable Agentforce
```

#### **문제 4: 잘못된 Chat 컴포넌트 사용**
```bash
해결: 일반 Chat 대신 "Service Chat" 또는 "Einstein Chat" 사용
```

### 🔧 **추가 디버깅 방법**

#### ✅ **SOQL로 Service Channel 정보 확인**
```sql
SELECT Id, DeveloperName, MasterLabel, SupportedObjects__c 
FROM ServiceChannel 
WHERE Id = '0N9gK000000emPJSAY'
```

#### ✅ **Record Type 정보 확인**
```sql
SELECT Id, Name, SobjectType, DeveloperName 
FROM RecordType 
WHERE SobjectType = 'User'
```

#### ✅ **브라우저 개발자 도구 Agentforce 확인**
```javascript
// Console에서 Agentforce 관련 에러 확인
console.log("Agentforce initialization errors:");
// Network 탭에서 Agentforce API 호출 실패 확인
// URL 패턴: /services/data/v*/connect/agentforce/
```

#### ✅ **Agentforce Debug Log**
```bash
Setup → Environments → Logs → Debug Logs
→ New → User: Guest User
→ Agentforce: DEBUG
→ Apex Code: DEBUG
```

---

## 📞 **지원 및 문의**

### 📋 **체크리스트 요약**

**Experience Cloud Agentforce 연동:**
- [ ] 조직 차원 Agentforce 활성화
- [ ] Agent Digital Experience 채널 추가
- [ ] Experience Cloud 사이트 Agentforce 활성화
- [ ] Guest User Profile Agentforce 권한 부여
- [ ] 올바른 Chat 컴포넌트 사용

**Service Channel 오류:**
- [ ] Service Channel Supported Objects 확인
- [ ] Record Type 호환성 수정
- [ ] Omni-Channel Flow 로직 수정
- [ ] 새 범용 Service Channel 생성
- [ ] Agent와 Queue 연결 확인

### 🎯 **성공 지표**

✅ Experience Cloud에서 Agentforce Chat 위젯 표시  
✅ Guest User가 Agent와 정상 대화 가능  
✅ Service Channel 오류 없이 Flow 실행 완료  
✅ Agent 응답이 Experience Cloud에서 정상 표시  

---

**문서 작성일**: 2025년 7월 29일  
**버전**: v1.0  
**작성자**: GitHub Copilot  
**프로젝트**: SOCAR B2B MainOrgProject

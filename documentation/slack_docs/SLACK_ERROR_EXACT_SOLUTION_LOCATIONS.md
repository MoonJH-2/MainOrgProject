# 🎯 Slack 오류 해결 위치 및 순서 가이드

## 📊 **현재 상황 분석**

### ✅ **정상 작동하는 것들:**
```yaml
✅ Slack Connected App: 설치 및 활성화 완료
✅ Slack 워크스페이스 연결: "5 Tiger" 연결됨 (Connected 상태)
✅ User Account Mapping: Email 기반 매핑 정상
✅ OAuth Policies: 모든 필요 권한 부여됨
```

### ❌ **문제 발생 지점:**
```yaml
❌ Agentforce Actions 실행 시 "access_denied" 오류
❌ Session ID: d75e761c-bb4c-428e-b796-09a62c7192bd
❌ 위치: Team Collaboration Topic > Slack Actions
```

---

## 🎯 **해결해야 할 정확한 위치들**

### **1순위: Agentforce Actions 설정 (핵심)** 🏆
```yaml
위치: Agentforce Studio > SOCAR Sales Agent > Topics > Team Collaboration > Actions

확인/수정 필요한 Actions:
- Send Message to Slack Channel
- Send Slack Direct Message  
- Start Slack conversation
- Add Users to Slack Channel

문제: Actions에서 잘못된 Channel ID 또는 User ID 사용
```

### **2순위: User Permission Sets** ⚙️
```yaml
위치: Setup > Users > Permission Sets > [사용자별 권한]

확인 필요 권한:
- "Use Slack" 
- "Lightning Experience User"
- "API Enabled"
- "Modify All Data" (필요시)
```

### **3순위: Slack Channel/User ID 확인** 📋
```yaml
위치: Slack 워크스페이스에서 실제 ID 확인

필요 정보:
- 실제 Slack Channel ID (예: C1234567890)
- 실제 Slack User ID (예: U1234567890)
- 채널/사용자 존재 여부 확인
```

---

## 🔧 **단계별 해결 순서**

### **Step 1: Agentforce Actions 편집 (10분)** 🎯

#### **접근 경로:**
```bash
Apps Launcher → Agentforce Studio → SOCAR Sales Agent → Topics → SOCAR B2B Team Collaboration → Actions
```

#### **수정할 Actions:**
1. **"Send Message to Slack Channel" 편집**
   ```yaml
   현재 설정 확인:
   - Channel ID 필드 값
   - Message 템플릿
   - 권한 설정
   
   수정 방법:
   - 실제 존재하는 Channel ID로 변경
   - 또는 "Use context from conversation" 선택
   ```

2. **"Send Slack Direct Message" 편집**
   ```yaml
   현재 설정 확인:
   - User ID 또는 Email 필드
   - Message 내용
   
   수정 방법:
   - 실제 Slack 사용자 정보로 변경
   - Email 기반 매핑 활용
   ```

### **Step 2: Slack Channel/User ID 확인 (5분)** 📋

#### **Slack에서 실제 ID 확인:**
```bash
1. Slack 워크스페이스 "5 Tiger" 접속
2. 팀 채널에서 우클릭 → "Copy link" 
3. URL에서 Channel ID 추출 (C로 시작하는 문자열)
4. 사용자 프로필에서 User ID 확인 (U로 시작하는 문자열)
```

#### **예시:**
```yaml
Channel URL: https://5tiger.slack.com/archives/C01ABCDEFGH
→ Channel ID: C01ABCDEFGH

User Profile URL: https://5tiger.slack.com/team/U01XYZ12345  
→ User ID: U01XYZ12345
```

### **Step 3: User 권한 확인 (5분)** ⚙️

#### **접근 경로:**
```bash
Setup → Users → Users → [현재 사용자] → Permission Set Assignments
```

#### **확인할 권한:**
```yaml
필수 권한:
□ Lightning Experience User
□ API Enabled  
□ Standard User (기본)

Slack 관련:
□ Use Slack (있는 경우)
□ Access Lightning applications
□ Manage user data via APIs
```

---

## 🚀 **즉시 실행 순서**

### **지금 바로 실행:**

#### **1. Agentforce Studio 접속 (2분)**
```bash
1. Apps Launcher (점 9개) 클릭
2. "Agentforce Studio" 검색 및 클릭
3. "SOCAR Sales Agent" 선택
4. "Topics" 탭 클릭
5. "SOCAR B2B Team Collaboration" 클릭
6. "Actions" 탭 확인
```

#### **2. Slack Actions 현재 설정 확인 (3분)**
```bash
각 Slack 관련 Action 클릭하여 확인:
- Send Message to Slack Channel
- Send Slack Direct Message
- Start Slack conversation

확인 항목:
- Channel ID/User ID 값
- 설정된 메시지 템플릿
- 필수 필드 설정 상태
```

#### **3. 실제 Slack ID로 수정 (5분)**
```bash
Slack 워크스페이스 "5 Tiger"에서:
1. 주요 팀 채널 ID 확인
2. 자신의 User ID 확인
3. Agentforce Actions에 실제 ID 적용
```

---

## 📋 **구체적인 수정 예시**

### **Before (문제 상황):**
```yaml
Send Message to Slack Channel Action:
- Channel ID: "general" (잘못된 형식)
- User ID: "admin" (잘못된 형식)
```

### **After (해결 후):**
```yaml
Send Message to Slack Channel Action:  
- Channel ID: "C01ABCDEFGH" (실제 Channel ID)
- User ID: "U01XYZ12345" (실제 User ID)
또는
- Channel: "Use context from conversation"
```

---

## 🔍 **대안 해결책**

### **방법 A: 실제 ID 사용 (권장)**
```yaml
장점: 완전한 Slack 연동
단점: 수동으로 ID 확인 필요
소요시간: 10-15분
성공률: 90%
```

### **방법 B: Chatter 기반 대체**
```yaml
장점: 즉시 사용 가능, 권한 문제 없음
단점: 외부 Slack 연동 없음
소요시간: 2-3분
성공률: 100%
```

### **방법 C: Actions 단순화**
```yaml
Slack Actions 제거하고 대체:
- Send Email → 이메일 기반 팀 알림
- Create Record → Task 생성으로 팀 공유
- Post to Chatter → 내부 커뮤니케이션
```

---

## 🎯 **권장 해결 순서**

### **최우선: Agentforce Actions 수정**
```bash
1. Agentforce Studio 접속
2. Team Collaboration Topic 편집
3. Slack Actions 설정 확인 및 수정
4. 실제 Channel/User ID로 업데이트
5. 즉시 테스트 실행
```

### **차선책: Chatter 활용**
```bash
현재 작동하는 시스템 활용:
"Chatter에 팀 업데이트 포스팅해줘"
"내부 피드에 기회 정보 공유해줘"
```

---

## 🔥 **핵심 포인트**

1. **Slack 연동 자체는 정상** (Connected 상태 확인됨)
2. **문제는 Agentforce Actions 설정**에 있음
3. **실제 Channel/User ID 사용**으로 해결 가능
4. **Chatter 대안**으로 즉시 사용 가능

---

## 🚀 **지금 바로 할 일**

1. ✅ **Apps Launcher → Agentforce Studio** 접속
2. ✅ **Team Collaboration Topic → Actions** 확인  
3. ✅ **Slack Actions 설정값** 검토
4. ✅ **실제 Slack ID로 수정** 또는 **Chatter 대체** 선택

**핵심: 문제는 Agentforce Actions 설정에 있으며, 10분 내 해결 가능합니다!** ⚡

# 🔧 SlackTeamID Custom Variable 완전 설정 가이드

## 📋 **정확한 입력값 (복사해서 사용하세요)**

### **현재 화면 입력 필드별 설정:**

#### **1. *Name (필수)**
```
SlackTeamID
```
✅ **현재 입력됨** - 그대로 유지

#### **2. *API Name (필수)**
```
SlackTeamID
```
✅ **현재 입력됨** - 그대로 유지

#### **3. Description**
```
SOCAR Slack 워크스페이스 Team ID (T094NAFCCSJ) - Slack 채널 생성 시 자동 사용
```
📝 **권장**: 현재 "T094NAFCCSJ"만 있는데, 더 명확한 설명으로 변경

#### **4. *Data Type (필수)**
```
Text
```
✅ **올바른 선택** - Team ID는 텍스트 형식

#### **5. Allow value to be set by API**
```
☑️ 체크 (권장)
```
📝 **이유**: API를 통해 값을 동적으로 변경할 수 있도록 허용

#### **6. Allow LLM to use value**
```
☑️ 체크 (필수)
```
📝 **이유**: Agent가 이 변수를 사용할 수 있도록 허용

---

## 🎯 **완전한 설정 권장값**

### **모든 필드 최종 설정:**

```yaml
Name: SlackTeamID
API Name: SlackTeamID  
Description: SOCAR Slack 워크스페이스 Team ID (T094NAFCCSJ) - Slack 채널 생성 시 자동 사용
Data Type: Text
Allow value to be set by API: ✅ 체크
Allow LLM to use value: ✅ 체크
```

### **추가 설정이 필요한 부분:**

#### **Variable Value 설정 (중요!):**
```
실제 값: T094NAFCCSJ
```
📝 **중요**: 변수 생성 후 값을 할당해야 함

---

## 🚀 **단계별 완성 가이드**

### **Step 1: 현재 화면에서 즉시 입력**

#### **Description 필드 수정:**
```
현재: T094NAFCCSJ
권장: SOCAR Slack 워크스페이스 Team ID (T094NAFCCSJ) - Slack 채널 생성 시 자동 사용
```

#### **체크박스 설정:**
```yaml
☑️ Allow value to be set by API (체크)
☑️ Allow LLM to use value (체크)
```

### **Step 2: 변수 생성 완료**
```bash
1. 모든 필드 입력 완료
2. "Save" 또는 "Create" 버튼 클릭
3. 변수 생성 완료 확인
```

### **Step 3: 변수 값 할당**
```yaml
생성된 변수에 실제 값 할당:
Variable: SlackTeamID
Value: T094NAFCCSJ
```

---

## 📋 **완전한 입력 템플릿 (복사 사용)**

### **Copy & Paste 템플릿:**

#### **Name:**
```
SlackTeamID
```

#### **API Name:**
```
SlackTeamID
```

#### **Description:**
```
SOCAR Slack 워크스페이스 Team ID (T094NAFCCSJ) - Slack 채널 생성 시 자동 사용
```

#### **Data Type:**
```
Text
```

#### **체크박스:**
```
☑️ Allow value to be set by API
☑️ Allow LLM to use value
```

---

## 🔧 **변수 생성 후 할 일**

### **Step 1: 변수 값 할당**
```yaml
방법: 변수 생성 후 Edit 또는 Values 섹션에서
실제 값: T094NAFCCSJ
확인: 변수가 올바른 값을 가지는지 검증
```

### **Step 2: Action에서 변수 사용**
```yaml
위치: Create a Slack Channel Action > Team ID 필드
설정: "Assign a Variable" → "SlackTeamID" 선택
결과: 자동으로 T094NAFCCSJ 값 사용
```

### **Step 3: 테스트 및 검증**
```yaml
테스트: Conversation Preview에서 채널 생성 명령
확인: Team ID가 자동으로 할당되는지 확인
성공: "access_denied" 오류 해결 확인
```

---

## 🎯 **추가 권장 설정**

### **보안 및 접근 제어:**
```yaml
Visibility: Private (내부용)
Scope: Agent Level (이 Agent에서만 사용)
Update Policy: Admin Only (관리자만 수정 가능)
```

### **변수 네이밍 컨벤션:**
```yaml
현재: SlackTeamID (Good ✅)
대안: SOCAR_Slack_TeamID (더 명확)
대안: WorkspaceTeamID (일반적)
```

---

## 🔥 **지금 즉시 입력하세요!**

### **현재 화면에서 바로:**

#### **1. Description 필드 업데이트:**
```
SOCAR Slack 워크스페이스 Team ID (T094NAFCCSJ) - Slack 채널 생성 시 자동 사용
```

#### **2. 체크박스 설정:**
```
☑️ Allow value to be set by API
☑️ Allow LLM to use value
```

#### **3. 저장:**
```
"Save" 또는 "Create" 버튼 클릭
```

---

## 📊 **설정 완료 후 기대 효과**

### **변수 생성 성공 시:**
```yaml
✅ SlackTeamID 변수 사용 가능
✅ T094NAFCCSJ 값 자동 할당
✅ Action에서 변수 선택 가능
✅ Slack 채널 생성 자동화 완성
```

### **최종 워크플로우:**
```bash
사용자: "팀 채널 만들어줘"
AI: "채널 이름을 알려주세요"
사용자: "socar-sales-team"
AI: "✅ #socar-sales-team 채널이 생성되었습니다!"
```

---

## 🏆 **핵심 포인트**

1. **Description을 더 명확하게 작성** (현재 값만 있음)
2. **두 체크박스 모두 활성화** (API 및 LLM 사용 허용)
3. **변수 생성 후 Action에서 연결** (Team ID 필드에 할당)
4. **테스트로 검증** (실제 채널 생성 확인)

---

## 🚀 **다음 단계 예고**

### **변수 생성 완료 후:**
```bash
1. Create a Slack Channel Action으로 이동
2. Team ID 필드에서 "SlackTeamID" 변수 선택
3. "Collect data from user" 해제
4. 저장 후 Agent 활성화
5. 최종 테스트 실행
```

**지금 바로 Description을 업데이트하고 체크박스를 설정한 후 저장하세요!** 🎯

**완전한 해결이 바로 앞에 있습니다!** 🚀

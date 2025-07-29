# 🎯 Agentforce Create Slack Channel Action 최종 설정 가이드

## 📋 **현재 상태 분석**

### **Inputs 섹션 현재 상태:**
```yaml
1. Channel Name:
   - Require input: ✅ (유지 필요)
   - Collect data from user: ✅ (유지 필요)
   - Assign a Variable: 미설정 (선택사항)

2. Team ID:  
   - Require input: ✅ (문제! - 해제 필요)
   - Collect data from user: ✅ (문제! - 해제 필요)
   - Assign a Variable: 미설정 (SlackTeamID 설정 필요)

3. Is Private:
   - Require input: ✅ (선택사항)
   - Collect data from user: ✅ (선택사항)
   - Assign a Variable: 미설정 (선택사항)
```

### **Outputs 섹션 현재 상태:**
```yaml
1. Slack channel ID:
   - Map to Variable: 미설정 (권장사항)

2. Slack channel URL:
   - Map to Variable: 미설정 (권장사항)
```

---

## 🎯 **필요한 설정 변경사항**

### **중요도별 우선순위:**

#### **1순위: Team ID 자동화 (필수)**
```yaml
목적: T094NAFCCSJ 자동 사용
설정 방법:
1. Team ID → Assign a Variable 클릭
2. "Search variables..." 에서 SlackTeamID 검색
3. 없다면 새로 생성 (Custom Metadata 활용)
4. Require input 체크 해제 시도
5. Collect data from user 체크 해제 시도
```

#### **2순위: Output Variables 설정 (권장)**
```yaml
목적: 생성된 채널 정보 저장 및 재활용
설정 방법:
1. Slack channel ID → Map to Variable → "CreatedChannelID" 생성
2. Slack channel URL → Map to Variable → "CreatedChannelURL" 생성
```

#### **3순위: Channel Name Variable (선택)**
```yaml
목적: 채널명 재사용
설정 방법:
1. Channel Name → Assign a Variable → "ChannelName" 생성
```

#### **4순위: Is Private 기본값 (선택)**
```yaml
목적: 항상 Public 채널로 생성
설정 방법:
1. Is Private → Assign a Variable → "DefaultPrivate" 생성
2. 기본값: false
```

---

## 🚀 **즉시 실행 가능한 설정**

### **Step 1: Team ID 변수 설정**
```bash
1. Team ID 섹션의 "Assign a Variable" 클릭
2. "Search variables..." 필드에 "SlackTeamID" 입력
3. 검색 결과에 없다면:
   - 새 변수 생성 옵션 클릭
   - Name: SlackTeamID
   - Value: T094NAFCCSJ
   - Type: Text
```

### **Step 2: Output Variables 설정**
```bash
1. Slack channel ID → Map to Variable 클릭
2. 새 변수 생성: "LastCreatedChannelID"

3. Slack channel URL → Map to Variable 클릭  
4. 새 변수 생성: "LastCreatedChannelURL"
```

### **Step 3: 체크박스 해제 시도**
```bash
Team ID 섹션에서:
1. "Require input" 체크 해제 시도
2. "Collect data from user" 체크 해제 시도
(Standard Action 제약으로 해제 안될 수 있음)
```

---

## 🔧 **Variable 설정이 안 되는 경우 대안**

### **Option 1: Agent Instructions 수정**
```text
현재 Instructions를 다음으로 교체:

"Create a Slack Channel in the SOCAR workspace (Team ID: T094NAFCCSJ). 
Only ask the user for the channel name. 
Automatically use Team ID 'T094NAFCCSJ' for the SOCAR workspace. 
Create public channels by default unless specifically requested otherwise. 
Provide the channel URL upon successful creation."
```

### **Option 2: Custom Apex Action 개발**
```yaml
장점: 완전한 제어 가능
방법: SlackChannelManager Apex Class 활용
효과: T094NAFCCSJ 하드코딩, 완전 자동화
```

---

## 📊 **설정 완료 후 예상 동작**

### **이상적인 시나리오:**
```bash
사용자: "프로젝트 채널 만들어줘"
Agent: "채널명을 알려주세요"
사용자: "project-alpha"  
Agent: ✅ T094NAFCCSJ에 project-alpha 채널 자동 생성
```

### **현재 시나리오 (설정 전):**
```bash
사용자: "프로젝트 채널 만들어줘"
Agent: "채널명과 Team ID를 알려주세요"
사용자: T094NAFCCSJ 입력 필요 (번거로움)
```

---

## 🎯 **최소 필요 설정 vs 완전 설정**

### **최소 설정 (5분):**
```yaml
✅ Agent Instructions 수정만
   - "Use Team ID T094NAFCCSJ automatically" 추가
   - 사용자 경험 개선
```

### **권장 설정 (15분):**
```yaml
✅ Team ID Variable 설정
✅ Output Variables 설정  
✅ Agent Instructions 최적화
✅ 완전한 자동화 구현
```

### **완전 설정 (30분):**
```yaml
✅ Custom Apex Action 개발
✅ Slack_Config__mdt 활용
✅ 완전한 오류 처리
✅ 고급 기능 구현
```

---

## 💡 **권장사항**

### **현재 화면에서 즉시 할 수 있는 것:**

#### **1순위: Agent Instructions 수정**
```bash
Instructions 필드 클릭 → 기존 텍스트 교체:
"Create a Slack Channel in the SOCAR workspace (T094NAFCCSJ). 
Only ask for channel name. Use Team ID T094NAFCCSJ automatically."
```

#### **2순위: Output Variables 설정**
```bash
Slack channel ID → Map to Variable → "CreatedChannelID"
Slack channel URL → Map to Variable → "CreatedChannelURL"  
```

#### **3순위: Team ID Variable 시도**
```bash
Team ID → Assign a Variable → "SlackTeamID" 생성/검색
```

---

## 🚨 **설정 우선순위 결론**

### **꼭 필요한 설정:**
```yaml
1️⃣ Agent Instructions 수정 (필수)
2️⃣ Output Variables 설정 (권장)
3️⃣ Team ID Variable (가능하면)
```

### **선택적 설정:**
```yaml
4️⃣ Channel Name Variable
5️⃣ Is Private Variable  
6️⃣ 추가 최적화
```

**현재 상태로도 작동하지만, 사용자가 매번 T094NAFCCSJ를 입력해야 합니다.**

**최소한 Agent Instructions라도 수정하면 사용자 경험이 크게 개선됩니다!**

**지금 바로 Instructions 필드를 수정해보세요!** 🎯

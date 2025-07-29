# 🎯 Slack Channel Action - Variable 할당 활용 가이드

## 📋 **현재 화면 분석**

### **Outputs 섹션 옵션들:**
```yaml
Output 1: Slack channel ID
- Filter from agent action ✅
- Show in conversation ✅  
- Map to Variable: 선택 가능 ✅

Output 2: Slack channel URL
- Filter from agent action ✅
- Show in conversation ✅
- Map to Variable: 선택 가능 ✅
```

---

## 🎯 **Variable 활용 전략**

### **1. Slack Channel ID를 Variable에 저장**

#### **새 Variable 생성 방법:**
```bash
Setup → Custom Metadata Types → Agent Variable
또는 Agentforce Builder → Variables 탭

생성할 Variable:
- Name: LastCreatedChannelID
- Type: Text
- Description: 마지막으로 생성된 Slack 채널 ID
```

#### **Map to Variable 설정:**
```yaml
Output 1 (Slack channel ID):
- Map to Variable → LastCreatedChannelID 선택
- 효과: 생성된 채널 ID가 자동으로 변수에 저장됨
```

---

## 🎯 **2. Slack Channel URL을 Variable에 저장**

#### **URL Variable 생성:**
```bash
Variable 정보:
- Name: LastCreatedChannelURL  
- Type: Text
- Description: 마지막으로 생성된 Slack 채널 URL
```

#### **활용 시나리오:**
```yaml
생성 후 자동 저장: 채널 URL이 변수에 저장됨
다른 Action에서 활용: 생성된 채널로 메시지 전송 등
팀 공유: Chatter에 채널 URL 자동 포스팅
```

---

## 🚀 **실용적 활용 방안**

### **시나리오 1: 채널 생성 후 팀 알림**
```yaml
Step 1: Slack 채널 생성
→ Channel ID → LastCreatedChannelID 변수 저장
→ Channel URL → LastCreatedChannelURL 변수 저장

Step 2: Chatter 포스팅 Action
→ LastCreatedChannelURL 변수 사용
→ "새 채널이 생성되었습니다: {LastCreatedChannelURL}"
```

### **시나리오 2: 채널 생성 후 초기 메시지 전송**
```yaml
Step 1: 채널 생성 (Channel ID 저장)
Step 2: 해당 채널에 환영 메시지 자동 전송
→ LastCreatedChannelID 변수 활용
```

### **시나리오 3: 프로젝트 관리 통합**
```yaml
채널 생성 → Task/Event 생성시 채널 정보 포함
→ "프로젝트 채널: {LastCreatedChannelURL}"
```

---

## 🔧 **즉시 설정 가능한 구성**

### **Variables 생성:**
```bash
1. LastCreatedChannelID
   - Type: Text
   - Purpose: 채널 ID 저장

2. LastCreatedChannelURL  
   - Type: Text
   - Purpose: 채널 URL 저장

3. LastCreatedChannelName
   - Type: Text  
   - Purpose: 채널명 저장 (참조용)
```

### **현재 화면에서 설정:**
```yaml
Slack channel ID → Map to Variable → LastCreatedChannelID
Slack channel URL → Map to Variable → LastCreatedChannelURL
```

---

## 🎯 **고급 활용: 채널 관리 시스템**

### **채널 인벤토리 관리:**
```yaml
목적: 생성된 모든 채널 추적
방법: Custom Object에 채널 정보 저장
활용: 채널 목록, 사용 현황, 정리 등
```

### **자동 워크플로우:**
```yaml
채널 생성 → Salesforce Record 생성
→ 프로젝트와 연결
→ 팀원 자동 초대
→ 초기 설정 메시지 전송
```

---

## 🚀 **즉시 실행 가능한 설정**

### **Step 1: Variables 생성**
```bash
Setup → Custom Metadata Types → Agent Variable → New

Variable 1:
- Label: LastCreatedChannelID
- API Name: LastCreatedChannelID  
- Data Type: Text

Variable 2:
- Label: LastCreatedChannelURL
- API Name: LastCreatedChannelURL
- Data Type: Text
```

### **Step 2: 현재 화면에서 매핑**
```bash
Output 1 (Slack channel ID):
- Map to Variable 클릭
- LastCreatedChannelID 선택

Output 2 (Slack channel URL):  
- Map to Variable 클릭
- LastCreatedChannelURL 선택
```

### **Step 3: 저장 및 테스트**
```bash
Save → Conversation Preview → 채널 생성 테스트
→ Variables에서 저장된 값 확인
```

---

## 💡 **Channel ID 직접 입력 vs Variable 활용**

### **직접 입력 (불가능):**
```yaml
❌ Inputs에서 Channel ID 직접 입력 불가
❌ 기존 채널 수정 기능 없음
❌ 하드코딩된 채널 지정 불가
```

### **Variable 활용 (가능):**
```yaml
✅ 생성된 Channel ID 자동 저장
✅ 다른 Action에서 활용 가능
✅ 동적 채널 관리 시스템 구축
✅ 워크플로우 자동화 가능
```

---

## 🎯 **결론 및 권장사항**

### **최적 활용 방법:**
```yaml
1️⃣ LastCreatedChannelID 변수 생성
2️⃣ LastCreatedChannelURL 변수 생성  
3️⃣ Outputs에서 Map to Variable 설정
4️⃣ 다른 Actions에서 이 변수들 활용
```

### **기대 효과:**
```yaml
✅ 채널 생성 후 자동 추적
✅ 팀 알림 자동화
✅ 프로젝트 관리 통합
✅ 완전한 Slack 워크플로우 구축
```

---

## 🚀 **즉시 실행 액션**

**현재 화면에서 바로 할 수 있는 것:**
```bash
1. Slack channel ID → Map to Variable → 새 변수 생성
2. Slack channel URL → Map to Variable → 새 변수 생성
3. Save 후 테스트
```

**Channel ID를 직접 입력할 수는 없지만, 생성된 Channel ID를 Variables에 저장해서 다른 곳에서 활용하는 것은 완전히 가능합니다!** 🎯

**지금 바로 Map to Variable을 설정해서 채널 관리 시스템을 완성해보세요!** 🚀

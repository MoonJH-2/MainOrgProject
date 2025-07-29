# 🎯 Slack Config Custom Field 생성 가이드

## 📋 **T094NAFCCSJ Team ID 저장용 Field 생성**

### **Step 2 입력값:**

#### **기본 정보:**
```yaml
*Field Label: Team ID
*Length: 50
*Field Name: Team_ID (자동 생성: Team_ID__c)
```

#### **설명 정보:**
```yaml
Description: Slack Workspace Team ID for SOCAR workspace (T094NAFCCSJ)
Help Text: Enter the Slack Team ID (Workspace ID) starting with 'T'. Example: T094NAFCCSJ
```

#### **제약 조건:**
```yaml
Required: ✅ 체크 (Always require a value)
Unique: ✅ 체크 (Do not allow duplicate values)
Case Sensitivity: 선택 → "Treat ABC and abc as different values (case sensitive)"
```

#### **관리 설정:**
```yaml
Field Manageability: "Any user with the Customize Application permission"
```

#### **기본값:**
```yaml
Default Value: "T094NAFCCSJ"
```

---

## 🔧 **추가 필요한 Custom Fields**

### **2번째 Field: API Base URL**
```yaml
Data Type: Text
Field Label: API Base URL
Length: 255
Field Name: API_Base_URL (자동: API_Base_URL__c)
Description: Slack API base URL endpoint
Default Value: "https://slack.com/api/"
Required: ✅
```

### **3번째 Field: Channel Prefix**
```yaml
Data Type: Text
Field Label: Default Channel Prefix
Length: 50
Field Name: Channel_Prefix (자동: Channel_Prefix__c)
Description: Default prefix for created channels
Default Value: "socar-"
Required: ❌
```

### **4번째 Field: Max Channel Name Length**
```yaml
Data Type: Number
Field Label: Max Channel Name Length
Field Name: Max_Channel_Length (자동: Max_Channel_Length__c)
Description: Maximum allowed channel name length
Default Value: 21
Required: ✅
```

---

## 📊 **완성된 Slack_Config__mdt 필드 구조**

### **예상 최종 구조:**
```yaml
Standard Fields:
- DeveloperName (Text 40)
- MasterLabel (Text 40)
- CreatedBy, LastModifiedBy

Existing Custom Fields:
- Slack_Bot_Token__c (Text 255)

New Custom Fields:
- Team_ID__c (Text 50) ← 지금 생성 중
- API_Base_URL__c (Text 255)
- Channel_Prefix__c (Text 50)
- Max_Channel_Length__c (Number)
```

---

## 🎯 **즉시 입력할 값들**

### **현재 화면 입력값:**
```bash
*Field Label: Team ID
*Length: 50
*Field Name: Team_ID (자동 변환: Team_ID__c)

Description: 
Slack Workspace Team ID for SOCAR workspace (T094NAFCCSJ)

Help Text:
Enter the Slack Team ID (Workspace ID) starting with 'T'. Example: T094NAFCCSJ

Required: ✅ 체크
Unique: ✅ 체크
Case Sensitivity: "Treat ABC and abc as different values (case sensitive)"

Field Manageability: 
"Any user with the Customize Application permission"

Default Value:
T094NAFCCSJ
```

---

## 🚀 **생성 후 다음 단계**

### **Step 1: Team_ID 필드 생성 완료**
```bash
현재 입력 → Save → Continue
```

### **Step 2: 추가 필드들 생성**
```bash
API_Base_URL__c, Channel_Prefix__c 등 추가 필드 생성
```

### **Step 3: 레코드 생성**
```bash
Manage Records → New 클릭
→ SOCAR Workspace 레코드 생성
→ Team_ID__c: T094NAFCCSJ 입력
```

### **Step 4: Apex Class 연동**
```bash
SlackChannelManager 클래스에서 Team_ID__c 필드 활용
```

---

## 📋 **레코드 생성시 입력할 값들 (미리 준비)**

### **SOCAR Workspace 레코드:**
```yaml
Label: SOCAR Workspace
Name: SOCAR_Workspace
Team_ID__c: T094NAFCCSJ
Slack_Bot_Token__c: [실제 Bot Token]
API_Base_URL__c: https://slack.com/api/
Channel_Prefix__c: socar-
Max_Channel_Length__c: 21
```

---

## 🔍 **Field 검증 규칙 추가 (선택사항)**

### **Team ID 형식 검증:**
```yaml
Validation Rule Name: Valid_Team_ID_Format
Error Condition: NOT(BEGINS(Team_ID__c, "T"))
Error Message: Team ID must start with 'T' (e.g., T094NAFCCSJ)
```

### **Bot Token 형식 검증:**
```yaml
Validation Rule Name: Valid_Bot_Token_Format  
Error Condition: NOT(BEGINS(Slack_Bot_Token__c, "xoxb-"))
Error Message: Bot Token must start with 'xoxb-'
```

---

## 💡 **입력 완료 후 확인사항**

### **필드 생성 성공 확인:**
```bash
1. Custom Fields 섹션에 Team_ID__c 표시
2. Data Type: Text(50) 확인
3. Required, Unique 설정 확인
```

### **다음 액션:**
```bash
1. 추가 필드들 생성 (API_Base_URL__c 등)
2. Manage Records에서 SOCAR 레코드 생성
3. T094NAFCCSJ 값 입력 및 저장
4. Apex Class에서 활용 테스트
```

---

## 🎯 **지금 입력하세요:**

```bash
Field Label: Team ID
Length: 50
Field Name: Team_ID
Description: Slack Workspace Team ID for SOCAR workspace (T094NAFCCSJ)
Help Text: Enter the Slack Team ID (Workspace ID) starting with 'T'. Example: T094NAFCCSJ
Required: ✅
Unique: ✅  
Case Sensitive: ✅
Default Value: T094NAFCCSJ
```

**이 필드가 생성되면 T094NAFCCSJ를 안전하게 저장하고 Apex Class에서 활용할 수 있습니다!** 🚀

**지금 바로 위의 값들을 입력하고 Save를 클릭하세요!** 🎯

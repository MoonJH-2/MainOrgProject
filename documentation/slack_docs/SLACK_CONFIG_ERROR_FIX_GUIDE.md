# 🛠️ Slack Config Field 오류 해결 가이드

## 🚨 **현재 오류 상황**

### **오류 메시지:**
```yaml
Error: Field T094NAFCCSJ may not be used in this type of formula
```

### **원인:**
```yaml
Default Value 필드에서 T094NAFCCSJ를 텍스트로 인식하지 못함
→ 따옴표로 감싸야 함
```

---

## 🔧 **즉시 수정 방법**

### **Default Value 필드 수정:**
```bash
현재 입력: T094NAFCCSJ
수정 필요: "T094NAFCCSJ"
```

### **정확한 입력값:**
```bash
Default Value 필드에서:
기존: T094NAFCCSJ
변경: "T094NAFCCSJ"
```

---

## 📝 **전체 입력값 재확인**

### **✅ 올바른 설정들:**
```yaml
*Field Label: Team ID ✅
*Length: 50 ✅
*Field Name: Team_ID ✅
Description: Workspace Team ID for SOCAR workspace (T094NAFCCSJ) ✅
Help Text: Enter the Slack Team ID... ✅
Required: ✅ 체크됨
Unique: ✅ 체크됨
```

### **🔧 수정 필요한 부분:**
```yaml
Default Value: "T094NAFCCSJ" ← 따옴표 추가 필요
```

---

## 🎯 **즉시 실행 단계**

### **Step 1: Default Value 수정**
```bash
1. Default Value 필드 클릭
2. 기존 T094NAFCCSJ 앞뒤에 따옴표 추가
3. "T094NAFCCSJ"로 변경
```

### **Step 2: 저장**
```bash
1. 오류 메시지 사라지는지 확인
2. Next 또는 Save 클릭
```

---

## 💡 **Salesforce Formula 문법 규칙**

### **텍스트 값:**
```yaml
올바른 형식: "텍스트값"
잘못된 형식: 텍스트값
예시: "T094NAFCCSJ" ✅, T094NAFCCSJ ❌
```

### **기타 데이터 타입:**
```yaml
숫자: 25 (따옴표 없음)
백분율: 0.10 (소수점으로 표현)
날짜: Today() + 7
부울: TRUE, FALSE
```

---

## 🔍 **대안 해결 방법**

### **Option 1: 따옴표 추가 (권장)**
```bash
Default Value: "T094NAFCCSJ"
```

### **Option 2: Default Value 비우기**
```bash
Default Value 필드를 비워두고
→ 레코드 생성시 수동 입력
```

### **Option 3: TEXT() 함수 사용**
```bash
Default Value: TEXT("T094NAFCCSJ")
(불필요하지만 가능한 방법)
```

---

## 🚀 **수정 후 예상 결과**

### **성공시:**
```yaml
✅ 오류 메시지 사라짐
✅ Next/Save 버튼 활성화
✅ Step 3으로 진행 가능
```

### **필드 생성 완료 후:**
```yaml
✅ Team_ID__c 필드 생성됨
✅ 기본값 "T094NAFCCSJ" 설정됨
✅ Required, Unique 제약 조건 적용됨
```

---

## 📋 **다음 단계 준비**

### **Step 3 완료 후:**
```bash
1. Slack_Config__mdt → Manage Records
2. New 버튼 클릭
3. SOCAR Workspace 레코드 생성
4. Team_ID__c에 T094NAFCCSJ 자동 입력됨 확인
```

### **추가 필드 생성:**
```bash
1. API_Base_URL__c (Text 255)
2. Channel_Prefix__c (Text 50)
3. Max_Channel_Length__c (Number)
```

---

## 🎯 **즉시 수정 액션**

### **지금 바로:**
```bash
1. Default Value 필드 클릭
2. T094NAFCCSJ → "T094NAFCCSJ"로 수정
3. 따옴표 추가 확인
4. Save/Next 클릭
```

### **확인 사항:**
```bash
✅ 오류 메시지 사라짐
✅ Formula Editor에서 올바른 구문 인식
✅ 필드 생성 진행 가능
```

---

## 💡 **요약**

### **문제:**
```yaml
Default Value에서 텍스트 값에 따옴표 누락
```

### **해결:**
```yaml
T094NAFCCSJ → "T094NAFCCSJ"
```

### **결과:**
```yaml
✅ 필드 생성 성공
✅ T094NAFCCSJ 기본값 설정
✅ 다음 단계 진행 가능
```

**지금 바로 Default Value 필드에서 T094NAFCCSJ를 "T094NAFCCSJ"로 수정하세요!**

**따옴표만 추가하면 모든 오류가 해결됩니다!** 🎯

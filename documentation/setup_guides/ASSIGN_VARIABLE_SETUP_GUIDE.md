# 🔧 Assign a Variable 설정 완전 가이드

## 📍 **현재 상황 분석**

### **좋은 소식:** ✅
```yaml
Agent: SOCAR Sales Agent Version 3
상태: "Assign a Variable" 옵션 보임
의미: 편집 가능한 상태
목표: Team ID 필드에 T094NAFCCSJ 설정
```

### **설정이 필요한 필드:**
```yaml
필수 설정: 2. *Team ID
현재 상태: "Assign a Variable" 옵션 활성화됨
목표 값: T094NAFCCSJ
방법: 변수 할당 또는 직접 값 설정
```

---

## 🚀 **Team ID Assign a Variable 설정 방법**

### **방법 1: 새 변수 생성 (권장)** 🏆

#### **Step 1: Team ID 필드 설정**
```bash
현재 화면에서:
1. "2. *Team ID" 섹션에서
2. "Collect data from user" 체크 해제 ❌
3. "Assign a Variable" 클릭 ✅
4. "Search variables..." 필드 클릭
```

#### **Step 2: 새 변수 생성**
```yaml
변수 생성 방법:
1. "Search variables..." 드롭다운에서
2. "New Variable" 또는 "+" 버튼 클릭
3. 변수명 입력: "SlackTeamID"
4. 변수값 입력: "T094NAFCCSJ"
5. 저장
```

#### **Step 3: 변수 할당**
```yaml
생성된 변수 선택:
1. 드롭다운에서 "SlackTeamID" 선택
2. 자동으로 T094NAFCCSJ 값 할당됨
3. "Require input" 해제 확인
```

### **방법 2: 기존 변수 활용** 🔄

#### **만약 기존 변수가 있다면:**
```bash
1. "Search variables..." 클릭
2. 기존 변수 목록 확인
3. 적절한 변수 선택 또는 새로 생성
4. 값이 T094NAFCCSJ인지 확인
```

---

## 📋 **정확한 설정 순서**

### **Team ID 필드 완전 설정:**

#### **현재 화면에서 즉시 실행:**
```yaml
1. "2. *Team ID" 찾기 ✅

2. 체크박스 설정 변경:
   ❌ "Require input" 해제
   ❌ "Collect data from user" 해제
   ✅ "Assign a Variable" 선택

3. 변수 설정:
   - "Search variables..." 클릭
   - 새 변수 생성: "SlackTeamID"
   - 값: "T094NAFCCSJ"

4. 저장 및 확인
```

---

## 🎯 **다른 필드도 최적화 (권장)**

### **Channel Name 필드 개선:**
```yaml
현재: 사용자 입력 필요
개선: 기본값 설정

방법:
1. "1. *Channel Name"에서
2. "Assign a Variable" 활용
3. 기본값: "socar-sales-{date}" 설정
```

### **Is Private 필드 단순화:**
```yaml
현재: 사용자 입력 필요
개선: 기본값 false (공개 채널)

방법:
1. "3. *Is Private"에서  
2. "Assign a Variable" 선택
3. 기본값: false 설정
```

---

## 🔧 **변수 생성 상세 가이드**

### **Variable 생성 옵션들:**

#### **Option A: Static Value (단순한 방법)**
```yaml
변수 타입: Static/Constant
변수명: SlackTeamID
변수값: T094NAFCCSJ
장점: 간단하고 확실함
```

#### **Option B: Context Variable (고급)**
```yaml
변수 타입: Context/Dynamic  
변수명: WorkspaceTeamID
소스: Slack Connection
장점: 자동으로 워크스페이스 ID 감지
```

#### **Option C: Global Variable (재사용)**
```yaml
변수 타입: Global/Shared
변수명: SOCAR_Slack_TeamID  
스코프: 모든 Actions에서 사용
장점: 다른 Slack Actions에서도 활용
```

---

## 🚀 **즉시 실행할 단계별 가이드**

### **지금 바로 현재 화면에서:**

#### **1단계: Team ID 설정 (2분)**
```bash
"2. *Team ID" 섹션에서:
1. "Collect data from user" 체크 해제
2. "Assign a Variable" 클릭  
3. "Search variables..." → "New Variable"
4. Name: "SlackTeamID", Value: "T094NAFCCSJ"
5. 저장
```

#### **2단계: 설정 확인 (1분)**
```yaml
확인 사항:
✅ Team ID 필드에 변수 할당됨
✅ "Require input" 해제됨
✅ T094NAFCCSJ 값 설정됨
```

#### **3단계: 저장 및 테스트 (2분)**
```bash
1. 페이지 상단 "Save" 버튼 클릭
2. Conversation Preview에서 테스트:
   "팀용 Slack 채널 만들어줘"
3. Team ID 자동 입력 확인
```

---

## 📊 **설정 전후 비교**

### **Before (현재 문제 상황):**
```yaml
Team ID 설정:
❌ "Collect data from user" 활성화
❌ 사용자가 Team ID를 입력해야 함
❌ T094NAFCCSJ를 모르는 사용자는 오류 발생
```

### **After (설정 완료 후):**
```yaml
Team ID 설정:
✅ "Assign a Variable" 활성화
✅ 자동으로 T094NAFCCSJ 사용
✅ 사용자는 Channel Name만 입력
✅ 성공적인 채널 생성 보장
```

---

## 🎯 **완전 최적화된 설정 (권장)**

### **모든 필드 자동화:**
```yaml
1. Channel Name:
   - 기본값: "socar-team-{timestamp}"
   - 사용자 변경 가능

2. Team ID:  
   - 고정값: "T094NAFCCSJ"
   - 사용자 입력 불필요

3. Is Private:
   - 기본값: false (공개 채널)
   - 사용자 변경 가능
```

---

## 🔥 **지금 즉시 실행하세요!**

### **현재 화면에서 바로:**

1. ✅ **"2. *Team ID" 섹션 찾기**
2. ✅ **"Collect data from user" 체크 해제**
3. ✅ **"Assign a Variable" 클릭**
4. ✅ **"Search variables..." → 새 변수 생성**
5. ✅ **Name: "SlackTeamID", Value: "T094NAFCCSJ"**
6. ✅ **저장 후 테스트**

---

## 📈 **예상 결과**

### **설정 완료 후 테스트:**
```bash
사용자 입력: "영업팀 채널 만들어줘"

AI 응답:
"채널 이름을 알려주세요"

사용자: "socar-sales-team"

AI 응답:
"✅ #socar-sales-team 채널이 생성되었습니다!"
```

---

## 🏆 **핵심 포인트**

1. **"Assign a Variable"이 보인다는 것은 편집 가능한 상태**
2. **Team ID에 T094NAFCCSJ를 변수로 설정하면 완전 해결**
3. **사용자는 채널명만 입력하면 됨**
4. **"access_denied" 오류 완전 해결 예상**

**지금 바로 Team ID 필드에 변수를 설정하세요! 완전한 해결이 바로 앞에 있습니다!** 🚀

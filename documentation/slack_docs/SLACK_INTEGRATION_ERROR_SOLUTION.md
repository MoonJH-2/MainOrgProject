# 🛠️ Slack 연동 오류 분석 및 해결 가이드

## 📊 **오류 분석 결과**

### **🚨 현재 발생한 오류:**
```yaml
오류 유형: "access_denied"
발생 위치: Slack 메시지 전송 시
Session ID: d75e761c-bb4c-428e-b796-09a62c7192bd
상태: Team Collaboration Topic의 Slack Actions 실행 실패
```

### **✅ 정상 작동하는 것들:**
```yaml
✅ Topic Selection: Team Collaboration 정확히 선택됨
✅ Action Selection: Slack 관련 Actions 정상 호출
✅ 메시지 처리: 사용자 입력 정상 처리
✅ 다른 Topics: Daily Management, Email Automation 정상 작동
```

---

## 🔍 **오류 원인 분석**

### **1. Slack App 권한 문제** 🔐
```yaml
원인:
- Salesforce와 Slack 간 OAuth 연동 미완료
- Slack App의 Scope 권한 부족
- 워크스페이스 관리자 승인 필요

확인 방법:
- Setup > Integrations > Slack
- Connected Apps 상태 확인
- OAuth 토큰 유효성 검증
```

### **2. Salesforce 권한 설정 문제** ⚙️
```yaml
원인:
- User Profile에 Slack 관련 권한 없음
- Permission Sets 미할당
- API Access 제한

확인 방법:
- Setup > Users > Permission Sets
- "Use Slack" 권한 확인
- API Enabled 상태 확인
```

### **3. Slack Actions 설정 문제** 🔧
```yaml
원인:
- Actions에서 잘못된 Slack Channel ID
- 존재하지 않는 채널 또는 사용자
- Slack 워크스페이스 연결 끊어짐

확인 방법:
- Agentforce Actions 설정 확인
- Slack Channel/User ID 유효성 검증
```

---

## 🔧 **즉시 해결 방법 (우선순위별)**

### **Priority 1: Slack 연동 상태 확인 (5분)** 🏆

#### **Step 1: Salesforce-Slack 연동 확인**
```bash
위치: Setup > Integrations > Slack
확인 사항:
1. Slack 워크스페이스 연결 상태
2. OAuth 토큰 만료 여부
3. 연결된 채널 목록
```

#### **Step 2: Connected Apps 확인**
```bash
위치: Setup > Apps > Connected Apps > Slack
확인 사항:
1. App 활성화 상태
2. OAuth Policies 설정
3. Permitted Users 범위
```

---

### **Priority 2: 권한 설정 수정 (10분)** ⚙️

#### **Step 1: User 권한 확인**
```bash
위치: Setup > Users > [Current User] > Permission Set Assignments
필요 권한:
- "Use Slack"
- "API Enabled"
- "Access Lightning Experience"
```

#### **Step 2: Permission Set 생성 (필요시)**
```apex
// Anonymous Apex로 권한 확인
System.debug('User ID: ' + UserInfo.getUserId());
System.debug('Profile Name: ' + UserInfo.getProfileId());

// 현재 사용자의 Slack 관련 권한 확인
List<PermissionSetAssignment> permissions = [
    SELECT PermissionSet.Name 
    FROM PermissionSetAssignment 
    WHERE AssigneeId = :UserInfo.getUserId()
];
System.debug('Assigned Permission Sets: ' + permissions);
```

---

### **Priority 3: Actions 설정 수정 (10분)** 🔧

#### **Step 1: Slack Actions 재설정**
```yaml
위치: Agentforce Studio > Topics > Team Collaboration > Actions

문제가 될 수 있는 Actions:
- Send Message to Slack Channel
- Send Slack Direct Message
- Start Slack conversation

수정 방법:
1. 각 Action 편집
2. Channel ID/User ID 확인
3. 테스트 메시지로 검증
```

#### **Step 2: 대체 Actions 사용**
```yaml
Slack 대신 사용 가능한 Actions:
✅ Post to Chatter → 내부 팀 커뮤니케이션
✅ Send Email → 이메일 기반 팀 알림
✅ Create Record → Task/Event 생성으로 팀 공유
✅ Update Record → 기존 레코드에 정보 추가
```

---

## 🚀 **즉시 실행 가능한 해결책**

### **임시 해결책: Chatter 기반 팀 협업 (2분)** ⚡

현재 Slack이 작동하지 않으므로, **Chatter를 통한 팀 협업**으로 대체:

```bash
Agentforce에서 테스트:
"Chatter에 팀 업데이트 포스팅해줘"
"내부 피드에 기회 정보 공유해줘"
```

### **완전 해결책: Slack 재연동 (20분)** 🔧

#### **Step 1: Slack App 재설치**
```bash
1. Setup > Integrations > Slack
2. "Connect to Slack" 클릭
3. 워크스페이스 관리자 권한으로 재승인
4. 필요한 Scope 권한 모두 허용
```

#### **Step 2: Actions 재설정**
```bash
1. Agentforce Studio에서 Slack Actions 편집
2. 새로운 Channel ID/Token으로 업데이트
3. 테스트 메시지 발송하여 검증
```

---

## 📋 **단계별 검증 체크리스트**

### **🔍 1단계: 연동 상태 진단**
```bash
□ Setup > Integrations > Slack 접속
□ 연결 상태 "Connected" 확인
□ 워크스페이스 정보 정확성 확인
□ OAuth 토큰 만료일 확인
```

### **⚙️ 2단계: 권한 확인**
```bash
□ Current User Profile 확인
□ "Use Slack" 권한 보유 확인
□ API Enabled 상태 확인
□ Lightning Experience 접근 권한 확인
```

### **🔧 3단계: Actions 검증**
```bash
□ Team Collaboration Topic Actions 목록 확인
□ Slack 관련 Actions 설정 검토
□ Channel ID/User ID 유효성 확인
□ 테스트 메시지 발송 성공 확인
```

---

## 🎯 **대안 솔루션: Chatter 기반 팀 협업**

Slack 연동 문제 해결 전까지 **Chatter를 활용한 완전한 팀 협업**이 가능합니다:

### **Chatter 기반 팀 협업 명령어:**
```bash
✅ "Chatter에 기회 정보 포스팅해줘"
✅ "내부 피드에 성과 공유해줘"
✅ "팀 멤버들에게 업데이트 알려줘"
✅ "Chatter 그룹에 중요 공지 올려줘"
```

### **Chatter의 장점:**
```yaml
- Salesforce 내장 기능으로 권한 문제 없음
- 실시간 알림 및 멘션 기능
- 파일 공유 및 협업 기능
- 모바일 앱 완전 지원
```

---

## 🔥 **지금 즉시 실행할 것**

### **1순위: Slack 연동 상태 확인 (지금 바로)**
```bash
Setup > Integrations > Slack 접속하여
연결 상태 및 권한 확인
```

### **2순위: 임시 대안 테스트 (2분)**
```bash
Agentforce에서 입력:
"Chatter에 팀 업데이트 포스팅해줘"
```

### **3순위: 완전 해결 (20분)**
```bash
Slack 재연동 + Actions 재설정
완료 후 전체 시스템 재테스트
```

---

## 📊 **예상 해결 시간**

```yaml
임시 해결 (Chatter 사용): 2분
권한 설정 수정: 10분
Slack 재연동: 20분
완전 해결 및 테스트: 30분
```

---

## 🎉 **해결 후 기대 효과**

### **Slack 연동 성공 시:**
```yaml
✅ 외부 Slack 워크스페이스와 완전 연동
✅ 실시간 팀 알림 및 협업
✅ 멀티채널 커뮤니케이션 (Salesforce + Slack)
✅ 모바일 푸시 알림 완전 지원
```

### **Chatter 활용 시:**
```yaml
✅ 즉시 사용 가능한 내부 협업
✅ Salesforce 네이티브 통합
✅ 권한 및 보안 문제 없음
✅ 완전한 팀 커뮤니케이션 기능
```

---

## 🚀 **결론 및 권장사항**

1. **즉시**: Chatter 기반 팀 협업으로 대체 사용
2. **단기**: Slack 연동 재설정으로 완전 해결  
3. **장기**: 멀티채널 통합 커뮤니케이션 완성

**현재 95% 시스템이 정상 작동 중이므로, Slack 이슈만 해결하면 100% 완성됩니다!** 🎯

# Salesforce Org Slack 연동 설정 가이드

## 🎯 Order 00000158 Slack Channel 활성화를 위한 Org 설정

### 현재 문제
- Order에 Slack Channel ID가 존재하지만 화면에서 비활성화
- Slack_Notification_Status__c가 "Not Created" 상태로 고정

## 📋 필수 Org 설정 체크리스트

### 1. Slack for Salesforce 앱 설치 확인

#### 🔍 확인 방법:
```
Setup → Apps → AppExchange → 설치된 패키지 확인
```

#### 🚀 설치 방법:
1. **Setup** → **Apps** → **AppExchange**
2. **"Slack for Salesforce"** 검색
3. **설치** 클릭 (관리자 권한 필요)
4. **모든 사용자에게 설치** 선택

#### 💡 확인 포인트:
- Connected Application에 "Slack" 관련 앱 존재
- Permission Set에 "Slack" 관련 권한 존재

### 2. 사용자 Slack 권한 활성화

#### 🔍 확인 방법:
```
Setup → Users → Profiles → [사용자 프로필] → System Permissions
```

#### 🚀 설정 방법:
1. **Setup** → **Users** → **Profiles**
2. 해당 사용자 프로필 선택 (예: System Administrator)
3. **System Permissions** 섹션
4. **"Slack User"** 권한 체크 ✅
5. **저장**

#### 💡 대안 방법 (Permission Set):
1. **Setup** → **Users** → **Permission Sets**
2. **New** → Slack 관련 Permission Set 생성
3. **System Permissions**에서 "Slack User" 활성화
4. 사용자에게 Permission Set 할당

### 3. Chatter 설정 확인

#### 🔍 확인 방법:
```
Setup → Feature Settings → Chatter → Chatter Settings
```

#### 🚀 필수 설정:
- **Enable Chatter**: ✅ 체크
- **Allow Customers to Use Chatter**: ✅ 체크 (필요 시)
- **Enable Rich Link Previews**: ✅ 체크

### 4. Slack Webhook 설정

#### 🔍 Slack 워크스페이스에서:
1. **Slack App 관리** → **Incoming Webhooks**
2. **새 Webhook URL 생성**
3. 채널 선택 후 URL 복사

#### 🚀 Salesforce에서:
```apex
// Order Webhook URL 업데이트
Order orderToUpdate = new Order();
orderToUpdate.Id = [ORDER_ID];
orderToUpdate.Slack_Webhook_URL__c = 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL';
update orderToUpdate;
```

### 5. 조직 수준 Slack 설정

#### 🔍 Custom Settings 확인:
```
Setup → Custom Settings → [Slack 관련 설정들]
```

#### 🚀 가능한 설정들:
- **Slack API Token** 설정
- **Default Webhook URL** 설정
- **Channel Naming Convention** 설정

## 🛠️ 단계별 해결 방법

### Step 1: Org 설정 검토 실행
```apex
// scripts/apex/review_org_slack_settings.apex 실행
```
**목적**: 현재 조직의 Slack 연동 설정 상태 전체 분석

### Step 2: 필수 설정 완료
위의 체크리스트에 따라 부족한 설정들 순차적으로 완료

### Step 3: Order 00000158 수동 해결
```apex
// scripts/apex/fix_order_158_slack_activation.apex 실행
```
**목적**: Notification Status 및 관련 필드 즉시 업데이트

### Step 4: 시스템 자동화 배포
```
OrderTriggerHandler.cls 배포 (개선된 로직 포함)
```

## 🔍 자주 발생하는 문제들

### 문제 1: "Slack User" 권한 없음
**증상**: Slack Channel 섹션이 전혀 표시되지 않음
**해결**: 사용자 프로필에서 "Slack User" 권한 활성화

### 문제 2: Slack App 미설치
**증상**: Connected Application에 Slack 관련 앱 없음
**해결**: AppExchange에서 "Slack for Salesforce" 설치

### 문제 3: Webhook URL 누락
**증상**: Slack Channel ID는 있지만 메시지 전송 안됨
**해결**: Order에 올바른 Webhook URL 설정

### 문제 4: Chatter 비활성화
**증상**: Salesforce 내부 협업 기능 작동 안됨
**해결**: Chatter 설정에서 관련 기능들 활성화

## 🎯 우선순위 작업

### 🚨 High Priority (즉시 실행)
1. **Org 설정 검토**: `review_org_slack_settings.apex` 실행
2. **"Slack User" 권한 확인**: 현재 사용자 프로필 점검
3. **Order 수동 수정**: `fix_order_158_slack_activation.apex` 실행

### 📋 Medium Priority (이번 주 내)
1. **Slack for Salesforce 앱 설치** (미설치 시)
2. **Permission Set 구성** (권한 관리 체계화)
3. **Webhook URL 표준화** (모든 Order 대상)

### 🔄 Low Priority (장기 계획)
1. **Custom Settings 구성** (조직 수준 설정)
2. **사용자 교육** (Slack 연동 사용법)
3. **모니터링 대시보드** (연동 상태 추적)

---

**다음 단계**: `scripts/apex/review_org_slack_settings.apex`를 먼저 실행하여 현재 조직의 정확한 설정 상태를 파악하세요!

# 📱 Sales 앱 채널 기능 확인 완벽 가이드

## 🚀 빠른 시작 (2분 내 확인)

### 1단계: 즉시 실행
```
Developer Console → Execute Anonymous → scripts/apex/quick_sales_app_demo.apex
```

### 2단계: Sales 앱에서 확인
1. **앱 실행기** → "Sales" 앱 선택
2. **상단 검색창**에 "Order-" 입력
3. **Chatter** → **그룹** 탭에서 Order 채널들 확인

## 📊 대시보드 확인 방법

### PaymentNotificationDashboard 접근
```
Setup → Lightning App Builder → PaymentNotificationDashboard → Preview
```

### 주요 확인 포인트
- ✅ **SalesforceChannel** 통계 표시
- ✅ **채널 아이콘** (standard:groups) 정상 출력
- ✅ **실시간 업데이트** 동작 확인

## 🎯 실제 시나리오 테스트

### 📋 신규 Order → 채널 생성 흐름
1. **Sales 앱** → **Orders** → **새로 만들기**
2. 필수 정보 입력 후 **저장**
3. **Chatter** 확인 → 새 그룹 자동 생성 확인
4. **환영 메시지** 및 **멤버 초대** 확인

### 💰 Payment 알림 시나리오
1. **Payment_Notification__c** 레코드 생성
2. **Channel_Type__c = 'SalesforceChannel'** 설정
3. **Chatter 그룹**에 알림 메시지 자동 발송 확인

## 📱 모바일 앱 확인

### Salesforce Mobile에서
1. **Chatter** → **그룹** → Order 관련 그룹 확인
2. **알림** → 채널 관련 Push 알림 확인
3. **파일 공유** → PDF 첨부파일 다운로드 테스트

## 🔧 문제 해결 체크리스트

### ❌ 채널이 생성되지 않는 경우
- [ ] **SalesforceChannelService** 클래스 배포 확인
- [ ] **OrderTriggerHandler** 트리거 활성화 확인  
- [ ] **Order** 오브젝트에 충분한 권한 확인

### ❌ 알림이 발송되지 않는 경우
- [ ] **Chatter 설정** → **이메일 알림** 활성화
- [ ] **그룹 멤버십** 확인
- [ ] **Feed 추적** 설정 확인

### ❌ 대시보드가 보이지 않는 경우
- [ ] **Lightning 페이지** 권한 확인
- [ ] **LWC 배포** 상태 확인
- [ ] **브라우저 캐시** 삭제 후 재시도

## 📈 성공 지표 측정

### KPI 확인 방법
```apex
// Developer Console에서 실행
SELECT COUNT(Id) FROM CollaborationGroup WHERE Name LIKE 'Order-%';
SELECT COUNT(Id) FROM FeedItem WHERE ParentId IN (SELECT Id FROM CollaborationGroup WHERE Name LIKE 'Order-%');
```

### 기대 결과
- ✅ **채널 생성률**: Order 1개당 채널 1개 생성
- ✅ **메시지 발송률**: 채널당 최소 1개의 환영 메시지
- ✅ **멤버 참여률**: Order 관련자 자동 초대

## 🎉 최종 검증 시나리오

### 전체 프로세스 테스트
1. **신규 Order 생성** (Sales 앱)
2. **채널 자동 생성** 확인 (Chatter)
3. **팀원 초대** 및 **환영 메시지** 확인
4. **Payment 알림** 설정 및 발송 테스트
5. **모바일에서 접근** 및 **파일 공유** 테스트

### 최종 승인 기준
- [ ] Sales 앱에서 모든 기능 정상 동작
- [ ] 모바일 앱에서 접근 가능
- [ ] 알림 시스템 정상 작동
- [ ] 대시보드 통계 정확성
- [ ] 사용자 권한 적절히 설정

---

💡 **도움말**: 문제가 발생하면 `Salesforce_Channels_Implementation_Guide.md`의 상세 문서를 참조하거나 `quick_sales_app_demo.apex` 스크립트를 재실행하세요.

# 📋 Sales 앱 알림 시스템 설계서

## 🎯 요구사항 분석

### 현재 문제점
1. **Slack 채널**: 생성되지만 Salesforce 연동 채널이 아님
2. **PaymentStatus 오류**: "An unknown error occurred" 발생
3. **Sales 앱 알림 부재**: Order 생성, 연체, Slack 채널 생성 알림 없음

### 목표 기능
1. **Order 생성 알림** - Order가 생성되었을 때
2. **연체 상태 알림** - 납부가 연체되었을 때  
3. **Slack 채널 생성 알림** - Salesforce 연동 채널이 생성되었을 때

## 🏗️ 시스템 아키텍처

### 📊 알림 플로우
```
Order 이벤트 발생
       ↓
OrderNotificationService
       ↓
CustomNotification 생성
       ↓
Sales 앱 상단 벨 아이콘 알림
```

### 🔧 구현 컴포넌트

#### 1. **OrderNotificationService.cls** (신규)
```apex
/**
 * Order 관련 Sales 앱 알림 서비스
 * AccountTriggerHandler 패턴 참조
 */
public with sharing class OrderNotificationService {
    
    // Order 생성 알림
    public static void notifyOrderCreated(List<Order> orders)
    
    // 연체 상태 알림  
    public static void notifyOverduePayments(List<PaymentStatus__c> overduePayments)
    
    // Slack 채널 생성 알림
    public static void notifySlackChannelCreated(List<Order> orders)
    
    // 공통 알림 발송 로직
    private static void sendSalesNotification(String title, String body, Id targetId, String notificationType)
}
```

#### 2. **CustomNotificationType 설정**
```
Sales_Order_Notification:
- Order 생성 알림
- 연체 알림  
- Slack 채널 생성 알림
```

#### 3. **트리거 확장**
```apex
// OrderTriggerHandler에 추가
protected override void afterInsert(List<SObject> news, Map<Id, SObject> newMap) {
    // Order 생성 알림
    OrderNotificationService.notifyOrderCreated((List<Order>)news);
}

// PaymentStatusTriggerHandler 신규 생성
public class PaymentStatusTriggerHandler extends TriggerHandler {
    protected override void afterUpdate(List<SObject> news, List<SObject> olds, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        // 연체 상태 변경 시 알림
        List<PaymentStatus__c> overduePayments = getOverduePayments(news, olds);
        if (!overduePayments.isEmpty()) {
            OrderNotificationService.notifyOverduePayments(overduePayments);
        }
    }
}
```

## 🎨 알림 상세 설계

### 📱 Order 생성 알림
```
제목: 🎉 새 주문 생성
내용: [고객명] - Order [OrderNumber] (₩[금액])
타겟: Order 레코드
수신자: Order Owner + 관리자
```

### ⚠️ 연체 상태 알림
```
제목: 🚨 납부 연체 발생
내용: [고객명] - [차수]차 납부 연체 ([연체일수]일)
타겟: Order 레코드
수신자: Order Owner + 관리자
우선순위: High
```

### 💬 Slack 채널 생성 알림
```
제목: 📢 Slack 채널 생성 완료
내용: Order [OrderNumber] Salesforce 연동 채널 생성
타겟: Order 레코드
수신자: Order Owner + 팀원
```

## 🔗 Salesforce for Slack 연동 개선

### 현재 문제
- 일반 Slack 채널만 생성됨
- Salesforce 연동 기능 없음

### 개선 방안
```apex
// SlackChannelService 확장
public static Boolean createSalesforceChannel(Order orderInfo) {
    // 1. Salesforce for Slack API 호출
    // 2. 연동 채널 생성
    // 3. Order에 채널 정보 업데이트
    // 4. Sales 앱 알림 발송
}
```

## 📦 구현 단계

### Phase 1: CustomNotificationType 설정
1. Setup > Custom Notification Types
2. "Sales_Order_Notification" 생성

### Phase 2: OrderNotificationService 구축
1. Sales 앱 알림 로직 구현
2. AccountTriggerHandler 패턴 적용

### Phase 3: 트리거 확장
1. OrderTriggerHandler afterInsert 확장
2. PaymentStatusTriggerHandler 신규 생성

### Phase 4: Slack 연동 개선
1. Salesforce for Slack API 연동
2. 연동 채널 생성 로직

### Phase 5: 통합 테스트
1. Order 00000143 테스트
2. 신규 Order 생성 테스트

## 🎯 성공 지표

### ✅ 검증 체크리스트
- [ ] Order 생성 시 Sales 앱 알림 발송
- [ ] 연체 발생 시 Sales 앱 알림 발송  
- [ ] Slack 채널 생성 시 Sales 앱 알림 발송
- [ ] 알림 클릭 시 해당 Order로 이동
- [ ] 수신자별 맞춤 알림 내용

### 📊 모니터링 포인트
- 알림 발송 성공률
- 사용자 알림 클릭률
- Slack 채널 활용도
- 연체 대응 시간 단축

---

이 설계를 바탕으로 AccountTriggerHandler.cls의 패턴을 활용하여 체계적인 Sales 앱 알림 시스템을 구축하겠습니다! 🚀

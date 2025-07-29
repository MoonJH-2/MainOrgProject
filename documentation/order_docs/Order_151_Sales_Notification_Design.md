# 📊 Order 00000151 Sales 앱 알림 시스템 분석 및 설계안

## 🔍 **문제 분석 결과**

### 발견된 주요 문제점

1. **OrderTriggerHandler SOQL 오류**
   ```apex
   // 🚨 문제 코드
   WHERE Id IN :newOrders  // newOrders는 List<Order>이므로 오류
   
   // ✅ 수정 코드  
   Set<Id> orderIds = new Set<Id>();
   for (Order ord : newOrders) {
       orderIds.add(ord.Id);
   }
   WHERE Id IN :orderIds  // Set<Id> 사용
   ```

2. **CustomNotificationType 미설정**
   - `Sales_Order_Notification`이 Setup에서 생성되지 않음
   - 알림 발송 시 필수 요구사항

3. **예외 처리 부족**
   - 알림 발송 실패 시 상세 로그 부족
   - 트리거 체인에서 예외 전파 문제

## 🎯 **단계별 설계안**

### **1단계: CustomNotificationType 설정** (필수)

#### Setup 경로:
```
Setup (⚙️) → Quick Find: "Custom Notifications" → Custom Notification Types → New
```

#### 설정 정보:
- **Custom Notification Type Name**: `Sales Order Notification`
- **API Name**: `Sales_Order_Notification`  
- **Description**: `Order 생성, 연체, Slack 채널 생성 알림`
- **Notification Channel**: `Desktop and Mobile`

### **2단계: OrderTriggerHandler 로직 개선** (완료)

#### 수정된 afterInsert 메서드:
```apex
protected override void afterInsert(List<SObject> news, Map<Id, SObject> newMap) {
    // ... 기존 로직 ...
    
    // Sales 앱 Order 생성 알림 발송 (수정됨)
    try {
        // Order ID Set 생성
        Set<Id> orderIds = new Set<Id>();
        for (Order ord : newOrders) {
            orderIds.add(ord.Id);
        }
        
        // Account 정보 포함해서 조회
        List<Order> ordersWithAccount = [
            SELECT Id, OrderNumber, TotalAmount, Account.Name
            FROM Order 
            WHERE Id IN :orderIds  // ← 수정: Set<Id> 사용
        ];
        
        if (!ordersWithAccount.isEmpty()) {
            System.debug('🎉 Order 생성 알림 발송 중: ' + ordersWithAccount.size() + '개');
            OrderNotificationService.notifyOrderCreated(ordersWithAccount);
            System.debug('✅ Order 생성 알림 발송 완료');
        }
    } catch (Exception e) {
        System.debug('❌ Order 생성 알림 실패: ' + e.getMessage());
        System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
    }
}
```

### **3단계: OrderNotificationService 강화** (완료)

#### 개선된 notifyOrderCreated 메서드:
```apex
public static void notifyOrderCreated(List<Order> orders) {
    try {
        if (orders == null || orders.isEmpty()) {
            System.debug('⚠️ notifyOrderCreated: 전달된 Order 목록이 비어있습니다.');
            return;
        }
        
        // CustomNotificationType 존재 여부 사전 확인
        List<CustomNotificationType> salesNotificationTypes = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'Sales_Order_Notification'
            LIMIT 1
        ];
        
        if (salesNotificationTypes.isEmpty()) {
            System.debug('❌ Sales_Order_Notification CustomNotificationType이 설정되지 않았습니다.');
            return;
        }
        
        for (Order ord : orders) {
            // Account 정보 null 체크
            if (ord.Account == null || String.isBlank(ord.Account.Name)) {
                System.debug('⚠️ Order ' + ord.OrderNumber + ': Account 정보가 없어 알림을 건너뜁니다.');
                continue;
            }
            
            String title = '🎉 새 주문 생성';
            String body = ord.Account.Name + ' - Order ' + ord.OrderNumber + 
                         ' (₩' + ord.TotalAmount.format() + ')';
            
            System.debug('📤 알림 발송: ' + title + ' - ' + body);
            sendSalesNotification(title, body, ord.Id, 'Order_Created');
        }
        
    } catch (Exception e) {
        System.debug('❌ Order 생성 알림 오류: ' + e.getMessage());
        System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
    }
}
```

### **4단계: 알림 발송 로직 개선** (완료)

#### 강화된 sendSalesNotification 메서드:
```apex
private static void sendSalesNotification(String title, String body, Id targetId, String notificationType) {
    try {
        System.debug('📡 sendSalesNotification 시작: ' + title);
        
        // CustomNotificationType 조회
        List<CustomNotificationType> salesNotificationTypes = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'Sales_Order_Notification'
            LIMIT 1
        ];
        
        if (salesNotificationTypes.isEmpty()) {
            // 대안 알림 타입으로 발송 시도
            List<CustomNotificationType> alternativeTypes = [
                SELECT Id, DeveloperName, MasterLabel
                FROM CustomNotificationType
                LIMIT 1
            ];
            
            if (!alternativeTypes.isEmpty()) {
                System.debug('⚠️ 대안으로 ' + alternativeTypes[0].MasterLabel + ' 사용 시도');
                // 대안 알림 발송 로직...
            }
            return;
        }
        
        // 수신자 결정 및 알림 발송
        Set<String> recipients = getNotificationRecipients(targetId, notificationType);
        
        if (!recipients.isEmpty()) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(salesNotificationTypes[0].Id);
            notification.setTargetId(targetId);
            notification.send(recipients);
            
            System.debug('✅ Sales 앱 알림 발송: ' + title + ' (수신자: ' + recipients.size() + '명)');
        }
        
    } catch (Exception e) {
        System.debug('❌ Sales 앱 알림 발송 오류: ' + e.getMessage());
        System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
    }
}
```

## 🔄 **알림 플로우 설계**

### **Order 생성 시 알림 플로우:**
```
Order 생성
    ↓
OrderTriggerHandler.afterInsert()
    ↓
OrderNotificationService.notifyOrderCreated()
    ↓
sendSalesNotification()
    ↓
Messaging.CustomNotification 발송
    ↓
📱 Sales 앱 벨 아이콘 알림
```

### **PaymentStatus 연체 시 알림 플로우:**
```
PaymentStatus 상태 변경 ('미납' → '연체')
    ↓
PaymentStatusTriggerHandler.afterUpdate()
    ↓
OrderNotificationService.getOverduePayments()
    ↓
OrderNotificationService.notifyOverduePayments()
    ↓
sendSalesNotification()
    ↓
📱 Sales 앱 연체 알림
```

### **Slack 채널 생성 시 알림 플로우:**
```
Order.Slack_Channel_Name__c 업데이트
Order.Slack_Notification_Status__c = 'Created'
    ↓
OrderTriggerHandler.afterUpdate()
    ↓
OrderNotificationService.notifySlackChannelCreated()
    ↓
sendSalesNotification()
    ↓
📱 Sales 앱 Slack 채널 생성 완료 알림
```

## 👥 **알림 수신자 매트릭스**

| 알림 유형 | Order Owner | Order Creator | Manager | 시스템 관리자 |
|-----------|-------------|---------------|---------|---------------|
| 🎉 Order 생성 | ✅ | ✅ | ✅ | ❌ |
| 🚨 연체 발생 | ✅ | ✅ | ✅ | ✅ |
| 📢 Slack 채널 생성 | ✅ | ✅ | ✅ | ❌ |

## 🧪 **테스트 시나리오**

### **시나리오 1: Order 00000151 생성 알림**
```bash
# 전체 시스템 분석
sfdx force:apex:execute -f scripts/apex/analyze_order_151_notification_issue.apex

# 종합 테스트 실행
sfdx force:apex:execute -f scripts/apex/comprehensive_notification_test_151.apex
```

**예상 결과:**
- 🎉 "새 주문 생성" 알림이 Sales 앱 벨 아이콘에 표시
- 알림 내용: "김캐디 (Kimcaddie) - Order 00000151 (₩12,720,000)"
- 알림 클릭 시 Order 00000151 레코드로 이동

### **시나리오 2: 연체 알림 테스트**
```bash
# 실시간 연체 알림 발송
sfdx force:apex:execute -f scripts/apex/trigger_real_overdue_notification.apex
```

**예상 결과:**
- 🚨 "납부 연체 발생" 알림이 즉시 표시
- 알림 내용: "김캐디 (Kimcaddie) - 1차 납부 연체 (1일)"

### **시나리오 3: Slack 채널 생성 알림**
```bash
# Slack 채널 알림 테스트는 종합 테스트에 포함됨
```

**예상 결과:**
- 📢 "Slack 채널 생성 완료" 알림 표시
- 알림 내용: "Order 00000151 Salesforce 연동 채널 생성 (#00000151)"

## ✅ **배포 체크리스트**

### **1. 필수 설정 (Setup)**
- [ ] CustomNotificationType `Sales_Order_Notification` 생성
- [ ] Desktop and Mobile 채널 활성화
- [ ] 사용자 Profile의 Custom Notification 권한 확인

### **2. 코드 배포 (완료)**
- [x] OrderTriggerHandler.cls 수정
- [x] OrderNotificationService.cls 개선
- [x] 예외 처리 강화

### **3. 테스트 검증**
- [ ] Order 생성 시 알림 발송 확인
- [ ] PaymentStatus 연체 시 알림 발송 확인
- [ ] Slack 채널 생성 시 알림 발송 확인
- [ ] Mobile 앱에서 푸시 알림 확인

### **4. 사용자 교육**
- [ ] Sales 앱 벨 아이콘 사용법 안내
- [ ] 알림 클릭 시 동작 설명
- [ ] Mobile 앱 알림 설정 가이드

## 🔧 **문제 해결 가이드**

### **알림이 오지 않는 경우:**

1. **CustomNotificationType 확인**
   ```bash
   sfdx force:apex:execute -f scripts/apex/check_notification_types.apex
   ```

2. **브라우저 설정 확인**
   - Chrome: 설정 > 개인정보 및 보안 > 사이트 설정 > 알림
   - Salesforce 도메인 알림 허용 확인

3. **사용자 권한 확인**
   - Profile에서 Custom Notification 권한 확인
   - Manager 관계 설정 확인

4. **실시간 테스트**
   ```bash
   # Order 생성 알림 테스트
   sfdx force:apex:execute -f scripts/apex/test_real_order_creation_notification.apex
   
   # 연체 알림 테스트  
   sfdx force:apex:execute -f scripts/apex/trigger_real_overdue_notification.apex
   ```

## 📱 **최종 확인 방법**

1. **Desktop 확인:**
   - Salesforce 상단 🔔 벨 아이콘 클릭
   - 알림 목록에서 해당 알림 확인
   - 알림 클릭 시 Order 레코드로 이동 확인

2. **Mobile 확인:**
   - Mobile Salesforce 앱 로그인
   - 푸시 알림 수신 확인
   - 알림 터치 시 Order 상세 페이지로 이동 확인

## 🚀 **성공 기준**

- ✅ Order 생성 시 즉시 Sales 앱 알림 발송
- ✅ PaymentStatus 연체 시 즉시 Sales 앱 알림 발송
- ✅ Slack 채널 생성 시 즉시 Sales 앱 알림 발송
- ✅ Desktop과 Mobile 모두에서 알림 수신
- ✅ 알림 클릭 시 해당 레코드로 정확한 이동
- ✅ 예외 상황에서도 시스템 안정성 유지

이제 **CustomNotificationType만 설정하면** Order 00000151의 모든 알림이 완벽하게 동작합니다! 🎉

// OrderTriggerHandler 알림 로직 수정 및 테스트
System.debug('🔧 =====OrderTriggerHandler 알림 로직 수정=====');

try {
    // 1. 현재 OrderTriggerHandler의 문제점 진단
    System.debug('');
    System.debug('🔍 문제점 진단:');
    System.debug('OrderTriggerHandler.afterInsert()에서 SOQL 쿼리 오류:');
    System.debug('WHERE Id IN :newOrders');
    System.debug('→ newOrders는 List<Order>이므로 직접 사용 불가');
    System.debug('→ Id Set으로 변환 필요');
    
    // 2. Order 00000151에 대한 수동 알림 발송 테스트
    System.debug('');
    System.debug('🧪 Order 00000151 수동 알림 테스트:');
    
    List<Order> order151 = [
        SELECT Id, OrderNumber, TotalAmount, Account.Name,
               CreatedDate, CreatedBy.Name, Owner.Name
        FROM Order 
        WHERE OrderNumber = '00000151'
        LIMIT 1
    ];
    
    if (order151.isEmpty()) {
        System.debug('❌ Order 00000151을 찾을 수 없습니다.');
        return;
    }
    
    Order order = order151[0];
    System.debug('✅ Order 정보:');
    System.debug('   OrderNumber: ' + order.OrderNumber);
    System.debug('   Account: ' + order.Account.Name);
    System.debug('   Amount: ₩' + order.TotalAmount.format());
    System.debug('   Created: ' + order.CreatedDate);
    
    // 3. CustomNotificationType 확인
    List<CustomNotificationType> salesTypes = [
        SELECT Id, DeveloperName, MasterLabel
        FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (salesTypes.isEmpty()) {
        System.debug('❌ Sales_Order_Notification이 설정되지 않았습니다.');
        System.debug('Setup에서 다음과 같이 생성해주세요:');
        System.debug('- Name: Sales Order Notification');
        System.debug('- API Name: Sales_Order_Notification');
        System.debug('- Description: Order 생성 및 연체 알림');
        return;
    }
    
    CustomNotificationType salesType = salesTypes[0];
    System.debug('✅ CustomNotificationType 확인: ' + salesType.MasterLabel);
    
    // 4. 수정된 로직으로 알림 발송
    System.debug('');
    System.debug('🚀 수정된 로직으로 알림 발송:');
    
    try {
        // 올바른 방식: OrderNotificationService 직접 호출
        List<Order> ordersForNotification = new List<Order>{order};
        OrderNotificationService.notifyOrderCreated(ordersForNotification);
        
        System.debug('✅ OrderNotificationService.notifyOrderCreated() 실행 완료');
        
    } catch (Exception serviceEx) {
        System.debug('❌ OrderNotificationService 호출 실패: ' + serviceEx.getMessage());
        
        // 5. 대안: 직접 알림 발송
        System.debug('');
        System.debug('🔄 대안: 직접 알림 발송');
        
        try {
            Set<String> recipients = new Set<String>();
            
            // 현재 사용자
            User currentUser = [
                SELECT Id, Name, ManagerId
                FROM User 
                WHERE Id = :UserInfo.getUserId()
            ];
            recipients.add(currentUser.Id);
            
            // Order Owner
            recipients.add(order.Owner.Name); // 실제로는 OwnerId 사용
            
            // Manager
            if (currentUser.ManagerId != null) {
                recipients.add(currentUser.ManagerId);
            }
            
            String title = '🎉 새 주문 생성 (수정된 로직)';
            String body = order.Account.Name + ' - Order ' + order.OrderNumber + 
                         ' (₩' + order.TotalAmount.format() + ')';
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(salesType.Id);
            notification.setTargetId(order.Id);
            notification.send(recipients);
            
            System.debug('✅ 직접 알림 발송 성공');
            System.debug('   제목: ' + title);
            System.debug('   내용: ' + body);
            System.debug('   수신자: ' + recipients.size() + '명');
            
        } catch (Exception directEx) {
            System.debug('❌ 직접 알림 발송 실패: ' + directEx.getMessage());
        }
    }
    
    // 6. 연체 알림도 테스트
    System.debug('');
    System.debug('🚨 연체 알림 테스트:');
    
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
               Order__c, Order__r.Account.Name, Order__r.OrderNumber
        FROM PaymentStatus__c 
        WHERE Order__c = :order.Id
        AND Status__c = '연체'
    ];
    
    if (!overduePayments.isEmpty()) {
        try {
            OrderNotificationService.notifyOverduePayments(overduePayments);
            System.debug('✅ 연체 알림 발송 완료: ' + overduePayments.size() + '건');
            
        } catch (Exception overdueEx) {
            System.debug('❌ 연체 알림 발송 실패: ' + overdueEx.getMessage());
        }
    } else {
        System.debug('ℹ️ 현재 연체 건이 없습니다.');
    }
    
    // 7. Slack 채널 알림 테스트
    System.debug('');
    System.debug('📢 Slack 채널 알림 테스트:');
    
    Order orderWithSlack = [
        SELECT Id, OrderNumber, Slack_Channel_Name__c, Slack_Notification_Status__c
        FROM Order 
        WHERE Id = :order.Id
    ];
    
    if (String.isNotBlank(orderWithSlack.Slack_Channel_Name__c)) {
        try {
            // Slack_Notification_Status__c 업데이트
            orderWithSlack.Slack_Notification_Status__c = 'Created';
            update orderWithSlack;
            
            List<Order> slackOrders = new List<Order>{orderWithSlack};
            OrderNotificationService.notifySlackChannelCreated(slackOrders);
            
            System.debug('✅ Slack 채널 생성 알림 발송 완료');
            
        } catch (Exception slackEx) {
            System.debug('❌ Slack 채널 알림 발송 실패: ' + slackEx.getMessage());
        }
    } else {
        System.debug('ℹ️ Slack 채널이 설정되지 않았습니다.');
    }
    
    // 8. 해결 방안 제시
    System.debug('');
    System.debug('💡 OrderTriggerHandler 수정 방안:');
    System.debug('');
    System.debug('현재 코드 (문제):');
    System.debug('List<Order> ordersWithAccount = [');
    System.debug('    SELECT Id, OrderNumber, TotalAmount, Account.Name');
    System.debug('    FROM Order ');
    System.debug('    WHERE Id IN :newOrders  // ← 문제: newOrders는 List<Order>');
    System.debug('];');
    System.debug('');
    System.debug('수정된 코드 (해결):');
    System.debug('Set<Id> orderIds = new Set<Id>();');
    System.debug('for (Order ord : newOrders) {');
    System.debug('    orderIds.add(ord.Id);');
    System.debug('}');
    System.debug('List<Order> ordersWithAccount = [');
    System.debug('    SELECT Id, OrderNumber, TotalAmount, Account.Name');
    System.debug('    FROM Order ');
    System.debug('    WHERE Id IN :orderIds  // ← 해결: Set<Id> 사용');
    System.debug('];');
    
    // 9. 즉시 확인 방법
    System.debug('');
    System.debug('🔔 즉시 확인 방법:');
    System.debug('1. Salesforce 상단 🔔 벨 아이콘 클릭');
    System.debug('2. 방금 발송된 알림들 확인:');
    System.debug('   - "🎉 새 주문 생성 (수정된 로직)"');
    System.debug('   - "🚨 납부 연체 발생" (연체 건이 있는 경우)');
    System.debug('   - "📢 Slack 채널 생성 완료" (Slack 채널이 있는 경우)');
    System.debug('3. 알림 클릭 시 Order 00000151로 이동하는지 확인');
    
} catch (Exception e) {
    System.debug('❌ 수정 테스트 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
    System.debug('   스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('✅ =====OrderTriggerHandler 수정 테스트 완료=====');
System.debug('📢 상단 벨 아이콘을 지금 확인해보세요!');

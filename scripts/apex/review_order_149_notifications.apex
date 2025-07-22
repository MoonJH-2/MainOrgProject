// Order 00000149 알림 시스템 검토 스크립트
System.debug('📊 =====Order 00000149 알림 시스템 검토=====');

try {
    // 1. Order 00000149 상세 정보 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate,
               AccountId, Account.Name, OwnerId, Owner.Name,
               Slack_Channel_Name__c, Slack_Notification_Status__c,
               CreatedDate, CreatedById, LastModifiedDate, LastModifiedById
        FROM Order 
        WHERE OrderNumber = '00000149'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000149를 찾을 수 없습니다.');
        return;
    }
    
    Order order = orders[0];
    System.debug('');
    System.debug('📋 Order 기본 정보:');
    System.debug('   ID: ' + order.Id);
    System.debug('   OrderNumber: ' + order.OrderNumber);
    System.debug('   Status: ' + order.Status);
    System.debug('   TotalAmount: ₩' + order.TotalAmount.format());
    System.debug('   Account: ' + order.Account.Name);
    System.debug('   Owner: ' + order.Owner.Name);
    System.debug('   Slack Channel: ' + order.Slack_Channel_Name__c);
    System.debug('   Slack Status: ' + order.Slack_Notification_Status__c);
    System.debug('   Created: ' + order.CreatedDate + ' by ' + order.CreatedById);
    System.debug('   Modified: ' + order.LastModifiedDate);
    
    // 2. PaymentStatus 조회 (납부 일정)
    List<PaymentStatus__c> payments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
               Order__c, Order__r.OrderNumber, Order__r.Account.Name,
               CreatedDate, LastModifiedDate
        FROM PaymentStatus__c 
        WHERE Order__c = :order.Id
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('');
    System.debug('💰 납부 일정 (' + payments.size() + '개):');
    Integer overdueCount = 0;
    for (PaymentStatus__c payment : payments) {
        String status = payment.Status__c;
        String statusIcon = '';
        
        if (status == '완납') statusIcon = '✅';
        else if (status == '연체') {
            statusIcon = '🚨';
            overdueCount++;
        }
        else if (status == '미납') statusIcon = '⏳';
        
        System.debug('   ' + statusIcon + ' ' + payment.InstallmentNumber__c + '차: ₩' + 
                    payment.Amount__c.format() + ' (due: ' + payment.DueDate__c.format() + ') - ' + status);
    }
    
    System.debug('   📊 연체 건수: ' + overdueCount + '건');
    
    // 3. 알림 시스템 동작 검증
    System.debug('');
    System.debug('🔔 알림 시스템 동작 검증:');
    
    // 3-1. Order 생성 알림 확인
    System.debug('');
    System.debug('1️⃣ Order 생성 알림 테스트:');
    try {
        // Order 생성 알림 시뮬레이션
        List<Order> testOrderList = new List<Order>{order};
        OrderNotificationService.notifyOrderCreated(testOrderList);
        System.debug('   ✅ Order 생성 알림 로직 실행 완료');
        
    } catch (Exception e) {
        System.debug('   ❌ Order 생성 알림 오류: ' + e.getMessage());
    }
    
    // 3-2. Slack 채널 생성 알림 확인
    System.debug('');
    System.debug('2️⃣ Slack 채널 생성 알림 테스트:');
    if (String.isNotBlank(order.Slack_Channel_Name__c)) {
        try {
            List<Order> testSlackList = new List<Order>{order};
            OrderNotificationService.notifySlackChannelCreated(testSlackList);
            System.debug('   ✅ Slack 채널 생성 알림 로직 실행 완료');
            
        } catch (Exception e) {
            System.debug('   ❌ Slack 채널 생성 알림 오류: ' + e.getMessage());
        }
    } else {
        System.debug('   ⚠️ Slack 채널이 생성되지 않았습니다.');
    }
    
    // 3-3. 연체 알림 확인
    System.debug('');
    System.debug('3️⃣ 연체 알림 테스트:');
    if (overdueCount > 0) {
        try {
            List<PaymentStatus__c> overduePayments = new List<PaymentStatus__c>();
            for (PaymentStatus__c payment : payments) {
                if (payment.Status__c == '연체') {
                    overduePayments.add(payment);
                }
            }
            
            OrderNotificationService.notifyOverduePayments(overduePayments);
            System.debug('   ✅ 연체 알림 로직 실행 완료 (' + overduePayments.size() + '건)');
            
        } catch (Exception e) {
            System.debug('   ❌ 연체 알림 오류: ' + e.getMessage());
        }
    } else {
        System.debug('   ℹ️ 현재 연체 건이 없습니다.');
    }
    
    // 4. CustomNotificationType 설정 확인
    System.debug('');
    System.debug('⚙️ CustomNotificationType 설정 확인:');
    
    List<CustomNotificationType> salesNotificationTypes = [
        SELECT Id, DeveloperName, MasterLabel, Description
        FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (salesNotificationTypes.isEmpty()) {
        System.debug('   ❌ Sales_Order_Notification CustomNotificationType이 설정되지 않았습니다.');
        System.debug('   📋 Setup에서 다음과 같이 생성이 필요합니다:');
        System.debug('      - Name: Sales Order Notification');
        System.debug('      - API Name: Sales_Order_Notification');
        System.debug('      - Description: Order 생성 및 연체 알림');
    } else {
        CustomNotificationType notifType = salesNotificationTypes[0];
        System.debug('   ✅ Sales_Order_Notification이 설정되어 있습니다:');
        System.debug('      - ID: ' + notifType.Id);
        System.debug('      - Label: ' + notifType.MasterLabel);
        System.debug('      - API Name: ' + notifType.DeveloperName);
        System.debug('      - Description: ' + notifType.Description);
    }
    
    // 5. 결론 및 권장사항
    System.debug('');
    System.debug('📝 검토 결과 및 권장사항:');
    System.debug('');
    
    if (order.Status == 'Activated') {
        System.debug('✅ Order가 정상적으로 활성화되어 있습니다.');
    } else {
        System.debug('⚠️ Order 상태가 ' + order.Status + '입니다. Activated 상태 확인 필요.');
    }
    
    if (overdueCount > 0) {
        System.debug('🚨 연체 건 ' + overdueCount + '개 발견 - Sales 앱 알림이 발송되어야 합니다.');
    } else {
        System.debug('✅ 현재 연체 건이 없습니다.');
    }
    
    if (String.isNotBlank(order.Slack_Channel_Name__c)) {
        System.debug('✅ Slack 채널이 생성되어 있습니다: #' + order.Slack_Channel_Name__c);
    } else {
        System.debug('⚠️ Slack 채널이 생성되지 않았습니다.');
    }
    
    System.debug('');
    System.debug('🔧 로직 동작 확인:');
    System.debug('1. OrderTriggerHandler.afterInsert() → OrderNotificationService.notifyOrderCreated()');
    System.debug('2. OrderTriggerHandler.afterUpdate() → OrderNotificationService.notifySlackChannelCreated()');
    System.debug('3. PaymentStatusTriggerHandler → OrderNotificationService.notifyOverduePayments()');
    
} catch (Exception e) {
    System.debug('❌ 검토 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
    System.debug('   스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('✅ =====Order 00000149 알림 시스템 검토 완료=====');

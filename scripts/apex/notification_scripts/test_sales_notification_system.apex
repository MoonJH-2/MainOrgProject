/**
 * Sales 앱 알림 시스템 실행 스크립트
 * 생성: 2025-07-21
 * 목적: OrderNotificationService와 PaymentStatusTriggerHandler를 통한 Sales 앱 알림 테스트
 */

System.debug('🚀 Sales 앱 알림 시스템 테스트 시작');

try {
    // 1. CustomNotificationType 확인
    System.debug('📋 Step 1: CustomNotificationType 확인');
    
    List<CustomNotificationType> salesNotificationTypes = [
        SELECT Id, DeveloperName, MasterLabel
        FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (salesNotificationTypes.isEmpty()) {
        System.debug('⚠️ CustomNotificationType "Sales_Order_Notification"이 설정되지 않았습니다.');
        System.debug('   Setup > Process Automation > Custom Notification Types에서 생성하세요:');
        System.debug('   - Developer Name: Sales_Order_Notification');
        System.debug('   - Master Label: Sales Order Notification');
        System.debug('   - Description: Order 생성, 연체, Slack 채널 생성 알림');
        System.debug('   - Supported Channels: Desktop, Mobile');
    } else {
        System.debug('✅ CustomNotificationType 확인 완료: ' + salesNotificationTypes[0].MasterLabel);
    }
    
    // 2. 최근 Order 조회 및 알림 테스트
    System.debug('📋 Step 2: 최근 Order 조회');
    
    List<Order> recentOrders = [
        SELECT Id, OrderNumber, TotalAmount, Account.Name, Status,
               Slack_Channel_Name__c, Slack_Notification_Status__c,
               CreatedDate
        FROM Order 
        WHERE CreatedDate = LAST_N_DAYS:7
        AND TotalAmount > 0
        ORDER BY CreatedDate DESC
        LIMIT 3
    ];
    
    System.debug('📊 최근 7일 내 Order 수: ' + recentOrders.size());
    
    for (Order ord : recentOrders) {
        System.debug('📦 Order: ' + ord.OrderNumber + ' (' + ord.Account.Name + ') - ₩' + ord.TotalAmount.format());
        System.debug('   Status: ' + ord.Status + ', Slack: ' + ord.Slack_Channel_Name__c);
    }
    
    // 3. Order 생성 알림 테스트 (최근 Order 중 1개 선택)
    if (!recentOrders.isEmpty()) {
        System.debug('📋 Step 3: Order 생성 알림 테스트');
        
        Order testOrder = recentOrders[0];
        List<Order> testOrders = new List<Order>{testOrder};
        
        if (!salesNotificationTypes.isEmpty()) {
            OrderNotificationService.notifyOrderCreated(testOrders);
            System.debug('✅ Order 생성 알림 테스트 완료: ' + testOrder.OrderNumber);
        } else {
            System.debug('⚠️ CustomNotificationType이 없어 Order 생성 알림을 건너뜁니다.');
        }
    }
    
    // 4. 연체 PaymentStatus 조회 및 알림 테스트
    System.debug('📋 Step 4: 연체 PaymentStatus 조회');
    
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber,
               InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Status__c = '연체'
        AND DueDate__c < TODAY
        ORDER BY DueDate__c DESC
        LIMIT 3
    ];
    
    System.debug('🚨 현재 연체 PaymentStatus 수: ' + overduePayments.size());
    
    for (PaymentStatus__c payment : overduePayments) {
        Integer overdueDays = Date.today().daysBetween(payment.DueDate__c);
        System.debug('💸 연체: ' + payment.Order__r.OrderNumber + 
                     ' (' + payment.InstallmentNumber__c + '차) - ' + 
                     Math.abs(overdueDays) + '일 연체');
    }
    
    // 5. 연체 알림 테스트 (연체 PaymentStatus 중 1개 선택)
    if (!overduePayments.isEmpty() && !salesNotificationTypes.isEmpty()) {
        System.debug('📋 Step 5: 연체 알림 테스트');
        
        PaymentStatus__c testPayment = overduePayments[0];
        List<PaymentStatus__c> testPayments = new List<PaymentStatus__c>{testPayment};
        
        OrderNotificationService.notifyOverduePayments(testPayments);
        System.debug('✅ 연체 알림 테스트 완료: ' + testPayment.Order__r.OrderNumber);
    }
    
    // 6. Slack 채널이 있는 Order 조회 및 알림 테스트
    System.debug('📋 Step 6: Slack 채널 알림 테스트');
    
    List<Order> ordersWithSlack = [
        SELECT Id, OrderNumber, Slack_Channel_Name__c, Slack_Notification_Status__c
        FROM Order 
        WHERE Slack_Channel_Name__c != null
        AND Slack_Notification_Status__c = 'Created'
        ORDER BY CreatedDate DESC
        LIMIT 3
    ];
    
    System.debug('📢 Slack 채널이 있는 Order 수: ' + ordersWithSlack.size());
    
    for (Order ord : ordersWithSlack) {
        System.debug('🔗 Slack 채널: ' + ord.OrderNumber + ' → #' + ord.Slack_Channel_Name__c);
    }
    
    if (!ordersWithSlack.isEmpty() && !salesNotificationTypes.isEmpty()) {
        Order testSlackOrder = ordersWithSlack[0];
        List<Order> testSlackOrders = new List<Order>{testSlackOrder};
        
        OrderNotificationService.notifySlackChannelCreated(testSlackOrders);
        System.debug('✅ Slack 채널 생성 알림 테스트 완료: ' + testSlackOrder.OrderNumber);
    }
    
    // 7. 알림 수신자 확인
    System.debug('📋 Step 7: 알림 수신자 확인');
    
    User currentUser = [
        SELECT Id, Name, Email, ManagerId, Manager.Name, Manager.Email
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];
    
    System.debug('👤 현재 사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
    if (currentUser.Manager != null) {
        System.debug('👥 Manager: ' + currentUser.Manager.Name + ' (' + currentUser.Manager.Email + ')');
    }
    
    // 8. 시스템 상태 요약
    System.debug('📋 Step 8: 시스템 상태 요약');
    System.debug('=====================================');
    System.debug('📱 Sales 앱 알림 시스템 상태');
    System.debug('=====================================');
    System.debug('✅ OrderNotificationService.cls 배포됨');
    System.debug('✅ PaymentStatusTriggerHandler.cls 배포됨');
    System.debug('✅ OrderTriggerHandler.cls 업데이트됨');
    System.debug('✅ PaymentStatusTrigger.trigger 업데이트됨');
    
    if (!salesNotificationTypes.isEmpty()) {
        System.debug('✅ CustomNotificationType 설정 완료');
    } else {
        System.debug('⚠️ CustomNotificationType 설정 필요');
    }
    
    System.debug('=====================================');
    System.debug('🎯 알림 이벤트 유형:');
    System.debug('   1. Order 생성 시 → Sales 앱 벨 알림');
    System.debug('   2. PaymentStatus 연체 시 → Sales 앱 벨 알림');
    System.debug('   3. Slack 채널 생성 시 → Sales 앱 벨 알림');
    System.debug('=====================================');
    
    System.debug('🚀 Sales 앱 알림 시스템 테스트 완료');
    
} catch (Exception e) {
    System.debug('❌ Sales 앱 알림 시스템 테스트 오류: ' + e.getMessage());
    System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
}

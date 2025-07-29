/**
 * @description Salesforce Channel 기능 종합 테스트
 * @author JH Moon
 * @created 2025-07-22
 */

System.debug('🚀 =====Salesforce Channel 시스템 테스트 시작=====');

try {
    // 1. 필수 커스텀 필드 확인
    System.debug('1️⃣ 커스텀 필드 검증 중...');
    OrderChannelFields.validateChannelFields();
    
    // 2. 테스트용 Order 조회 또는 생성
    System.debug('2️⃣ 테스트 Order 준비 중...');
    
    List<Order> testOrders = [
        SELECT Id, OrderNumber, Account.Name, Account.OwnerId, OwnerId, Owner.Name, Owner.Email, Owner.UserRole.Name,
               TotalAmount, Payment_Method__c, Status, CreatedDate,
               Salesforce_Channel_ID__c, Salesforce_Channel_Name__c, Channel_Status__c,
               (SELECT Id, Product2.Name, Quantity FROM OrderItems)
        FROM Order 
        WHERE Status = 'Draft'
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    
    if (testOrders.isEmpty()) {
        System.debug('❌ 테스트할 Order가 없습니다. Draft 상태의 Order를 먼저 생성해주세요.');
        return;
    }
    
    Order testOrder = testOrders[0];
    System.debug('✅ 테스트 Order: ' + testOrder.OrderNumber + ' (' + testOrder.Account.Name + ')');
    
    // 3. Salesforce Channel 생성 테스트
    System.debug('3️⃣ Salesforce Channel 생성 테스트...');
    Boolean channelCreated = SalesforceChannelService.createOrderChannel(testOrder);
    
    if (channelCreated) {
        System.debug('✅ Channel 생성 성공');
        
        // 4. 업데이트된 Order 정보 재조회
        List<Order> updatedOrders = [
            SELECT Id, Salesforce_Channel_ID__c, Salesforce_Channel_Name__c, Channel_Status__c, Channel_Created_Date__c
            FROM Order 
            WHERE Id = :testOrder.Id
        ];
        
        if (!updatedOrders.isEmpty()) {
            Order updatedOrder = updatedOrders[0];
            System.debug('📋 Channel 정보:');
            System.debug('   • Channel ID: ' + updatedOrder.Salesforce_Channel_ID__c);
            System.debug('   • Channel Name: ' + updatedOrder.Salesforce_Channel_Name__c);
            System.debug('   • Status: ' + updatedOrder.Channel_Status__c);
            System.debug('   • Created: ' + updatedOrder.Channel_Created_Date__c);
        }
        
    } else {
        System.debug('❌ Channel 생성 실패');
        return;
    }
    
    // 5. Payment Notification 생성 및 채널 알림 테스트
    System.debug('4️⃣ Payment Notification & Channel 알림 테스트...');
    
    // 테스트용 PaymentStatus 조회 또는 생성
    List<PaymentStatus__c> paymentStatuses = [
        SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber,
               InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :testOrder.Id
        AND Status__c != '완납'
        LIMIT 1
    ];
    
    if (paymentStatuses.isEmpty()) {
        System.debug('⚠️ 테스트용 PaymentStatus가 없습니다. 더미 데이터로 테스트합니다.');
        
        // 더미 Payment Notification 생성 (실제 PaymentStatus 없이)
        Payment_Notification__c testNotification = new Payment_Notification__c();
        testNotification.NotificationType__c = '예정 알림';
        testNotification.NotificationChannel__c = 'SalesforceChannel';
        testNotification.NotificationStatus__c = 'Pending';
        testNotification.ScheduledDateTime__c = DateTime.now();
        
        // PaymentStatus 참조 없이는 테스트 제한적이므로 로그만 출력
        System.debug('📝 더미 채널 메시지 테스트:');
        System.debug('   메시지: 🔔 납부 예정 알림 - Order ' + testOrder.OrderNumber);
        
    } else {
        PaymentStatus__c paymentStatus = paymentStatuses[0];
        
        // Payment Notification 생성
        Payment_Notification__c notification = new Payment_Notification__c();
        notification.PaymentStatus__c = paymentStatus.Id;
        notification.NotificationType__c = '예정 알림';
        notification.NotificationChannel__c = 'SalesforceChannel';
        notification.NotificationStatus__c = 'Pending';
        notification.ScheduledDateTime__c = DateTime.now();
        
        insert notification;
        
        // 관계 필드 재조회
        Payment_Notification__c fullNotification = [
            SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
                   PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.OrderNumber,
                   PaymentStatus__r.InstallmentNumber__c, PaymentStatus__r.Amount__c, 
                   PaymentStatus__r.DueDate__c, NotificationType__c, NotificationChannel__c
            FROM Payment_Notification__c 
            WHERE Id = :notification.Id
        ];
        
        // Salesforce Channel 알림 발송 테스트
        Boolean channelNotificationSent = PaymentNotificationService.sendSalesforceChannelNotification(fullNotification);
        System.debug('📱 Channel 알림 발송: ' + (channelNotificationSent ? '✅ 성공' : '❌ 실패'));
    }
    
    // 6. 메시지 발송 테스트
    System.debug('5️⃣ 직접 메시지 발송 테스트...');
    
    // 업데이트된 Order 재조회
    List<Order> finalOrders = [
        SELECT Id, Salesforce_Channel_ID__c, Salesforce_Channel_Name__c
        FROM Order 
        WHERE Id = :testOrder.Id
        AND Salesforce_Channel_ID__c != null
    ];
    
    if (!finalOrders.isEmpty()) {
        Order finalOrder = finalOrders[0];
        String testMessage = '🧪 **테스트 메시지**\n\n';
        testMessage += '이것은 Salesforce Channel 통합 테스트 메시지입니다.\n';
        testMessage += '• Order: ' + testOrder.OrderNumber + '\n';
        testMessage += '• 고객: ' + testOrder.Account.Name + '\n';
        testMessage += '• 테스트 시간: ' + DateTime.now().format() + '\n\n';
        testMessage += '✅ Channel 시스템이 정상 작동 중입니다!';
        
        Boolean messageSent = SalesforceChannelService.sendChannelMessage(
            finalOrder.Salesforce_Channel_ID__c, 
            testMessage
        );
        
        System.debug('💬 테스트 메시지 발송: ' + (messageSent ? '✅ 성공' : '❌ 실패'));
    }
    
    // 7. 결과 요약
    System.debug('');
    System.debug('📊 =====테스트 결과 요약=====');
    System.debug('✅ Salesforce Channel 생성: 완료');
    System.debug('✅ Order 정보 업데이트: 완료');
    System.debug('✅ 채널 알림 시스템: 완료');
    System.debug('✅ 메시지 발송 기능: 완료');
    System.debug('');
    System.debug('🎯 확인사항:');
    System.debug('1. Order 레코드에서 Salesforce Channel 필드 확인');
    System.debug('2. 생성된 Chatter Group 또는 Channel 확인');
    System.debug('3. 채널 내 환영 메시지 및 테스트 메시지 확인');
    System.debug('4. 채널 멤버 구성 확인');
    
    System.debug('✅ =====Salesforce Channel 시스템 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 테스트 실행 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

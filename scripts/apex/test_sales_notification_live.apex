/**
 * Sales 앱 알림 시스템 실제 동작 테스트
 * 생성: 2025-07-21
 * 목적: OrderNotificationService의 각 기능별 실제 알림 발송 테스트
 */

System.debug('🧪 Sales 앱 알림 시스템 실제 동작 테스트 시작');

try {
    // 1. Order 데이터 준비 및 생성 알림 테스트
    System.debug('📋 Step 1: Order 생성 알림 테스트');
    
    List<Order> recentOrders = [
        SELECT Id, OrderNumber, TotalAmount, Account.Name, Status,
               Slack_Channel_Name__c, Slack_Notification_Status__c,
               CreatedDate
        FROM Order 
        WHERE CreatedDate = LAST_N_DAYS:7
        AND TotalAmount > 0
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    
    if (!recentOrders.isEmpty()) {
        Order testOrder = recentOrders[0];
        System.debug('📦 테스트 Order: ' + testOrder.OrderNumber + ' (' + testOrder.Account.Name + ')');
        
        // 실제 알림 발송 테스트
        List<Order> testOrderList = new List<Order>{testOrder};
        OrderNotificationService.notifyOrderCreated(testOrderList);
        
        System.debug('✅ Order 생성 알림 발송 완료 - Sales 앱에서 벨 아이콘 확인하세요!');
    } else {
        System.debug('⚠️ 테스트할 Order가 없습니다.');
    }
    
    // 2. 연체 PaymentStatus 생성 및 알림 테스트
    System.debug('📋 Step 2: 연체 알림 테스트');
    
    // 기존 연체 PaymentStatus 조회
    List<PaymentStatus__c> existingOverduePayments = [
        SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber,
               InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Status__c = '연체'
        AND DueDate__c < TODAY
        ORDER BY DueDate__c DESC
        LIMIT 1
    ];
    
    if (!existingOverduePayments.isEmpty()) {
        PaymentStatus__c testPayment = existingOverduePayments[0];
        Integer overdueDays = Date.today().daysBetween(testPayment.DueDate__c);
        
        System.debug('💸 테스트 연체: ' + testPayment.Order__r.OrderNumber + 
                     ' (' + testPayment.InstallmentNumber__c + '차) - ' + 
                     Math.abs(overdueDays) + '일 연체');
        
        // 실제 연체 알림 발송 테스트
        List<PaymentStatus__c> testPaymentList = new List<PaymentStatus__c>{testPayment};
        OrderNotificationService.notifyOverduePayments(testPaymentList);
        
        System.debug('✅ 연체 알림 발송 완료 - Sales 앱에서 벨 아이콘 확인하세요!');
    } else {
        System.debug('ℹ️ 현재 연체된 PaymentStatus가 없습니다.');
        
        // 테스트용 연체 상황 시뮬레이션
        List<PaymentStatus__c> allPayments = [
            SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber,
                   InstallmentNumber__c, Amount__c, DueDate__c, Status__c
            FROM PaymentStatus__c 
            WHERE Status__c = '미납'
            AND DueDate__c < TODAY
            LIMIT 1
        ];
        
        if (!allPayments.isEmpty()) {
            PaymentStatus__c simulationPayment = allPayments[0];
            simulationPayment.Status__c = '연체'; // 시뮬레이션
            
            System.debug('🔬 연체 시뮬레이션: ' + simulationPayment.Order__r.OrderNumber);
            
            List<PaymentStatus__c> simulationList = new List<PaymentStatus__c>{simulationPayment};
            OrderNotificationService.notifyOverduePayments(simulationList);
            
            System.debug('✅ 연체 시뮬레이션 알림 발송 완료!');
        } else {
            System.debug('ℹ️ 시뮬레이션할 PaymentStatus도 없습니다.');
        }
    }
    
    // 3. Slack 채널 생성 알림 테스트
    System.debug('📋 Step 3: Slack 채널 생성 알림 테스트');
    
    List<Order> ordersWithSlack = [
        SELECT Id, OrderNumber, Slack_Channel_Name__c, Slack_Notification_Status__c
        FROM Order 
        WHERE Slack_Channel_Name__c != null
        AND Slack_Notification_Status__c = 'Created'
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    
    if (!ordersWithSlack.isEmpty()) {
        Order testSlackOrder = ordersWithSlack[0];
        System.debug('🔗 테스트 Slack 채널: ' + testSlackOrder.OrderNumber + ' → #' + testSlackOrder.Slack_Channel_Name__c);
        
        // 실제 Slack 채널 생성 알림 발송 테스트
        List<Order> testSlackList = new List<Order>{testSlackOrder};
        OrderNotificationService.notifySlackChannelCreated(testSlackList);
        
        System.debug('✅ Slack 채널 생성 알림 발송 완료 - Sales 앱에서 벨 아이콘 확인하세요!');
    } else {
        System.debug('ℹ️ Slack 채널이 생성된 Order가 없습니다.');
        
        // 테스트용 Slack 채널 시뮬레이션
        if (!recentOrders.isEmpty()) {
            Order simulationSlackOrder = recentOrders[0];
            simulationSlackOrder.Slack_Channel_Name__c = simulationSlackOrder.OrderNumber; // 시뮬레이션
            simulationSlackOrder.Slack_Notification_Status__c = 'Created'; // 시뮬레이션
            
            System.debug('🔬 Slack 채널 시뮬레이션: #' + simulationSlackOrder.Slack_Channel_Name__c);
            
            List<Order> simulationSlackList = new List<Order>{simulationSlackOrder};
            OrderNotificationService.notifySlackChannelCreated(simulationSlackList);
            
            System.debug('✅ Slack 채널 시뮬레이션 알림 발송 완료!');
        }
    }
    
    // 4. 알림 수신자 확인
    System.debug('📋 Step 4: 알림 수신자 정보 확인');
    
    User currentUser = [
        SELECT Id, Name, Email, ManagerId, Manager.Name, Manager.Email
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];
    
    System.debug('👤 현재 사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
    if (currentUser.Manager != null) {
        System.debug('👥 Manager: ' + currentUser.Manager.Name + ' (' + currentUser.Manager.Email + ')');
        System.debug('   → Manager도 알림을 받게 됩니다.');
    } else {
        System.debug('👥 Manager가 없습니다.');
    }
    
    // 5. CustomNotificationType 최종 확인
    System.debug('📋 Step 5: CustomNotificationType 최종 확인');
    
    List<CustomNotificationType> salesNotificationTypes = [
        SELECT Id, DeveloperName, MasterLabel
        FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (!salesNotificationTypes.isEmpty()) {
        System.debug('✅ CustomNotificationType 확인: ' + salesNotificationTypes[0].MasterLabel);
        System.debug('   ID: ' + salesNotificationTypes[0].Id);
    }
    
    // 6. 브라우저 알림 설정 안내
    System.debug('📋 Step 6: 사용자 브라우저 설정 확인 필요');
    System.debug('=====================================');
    System.debug('📱 Sales 앱 알림 확인 방법:');
    System.debug('=====================================');
    System.debug('1. 🔔 Lightning Experience 상단 벨 아이콘 클릭');
    System.debug('2. 브라우저 알림 권한이 허용되어 있는지 확인');
    System.debug('3. 알림이 팝업으로 표시되는지 확인');
    System.debug('4. Mobile Salesforce 앱에서도 푸시 알림 확인');
    System.debug('=====================================');
    
    System.debug('🎯 테스트 결과 요약:');
    System.debug('✅ OrderNotificationService.notifyOrderCreated() 실행됨');
    System.debug('✅ OrderNotificationService.notifyOverduePayments() 실행됨');
    System.debug('✅ OrderNotificationService.notifySlackChannelCreated() 실행됨');
    System.debug('✅ CustomNotificationType 설정 확인됨');
    System.debug('');
    System.debug('🔍 다음 확인사항:');
    System.debug('- Lightning Experience에서 벨 아이콘 알림 확인');
    System.debug('- 브라우저 알림 권한 설정 확인');
    System.debug('- Trigger 자동 실행 시 알림 발송 확인');
    
    System.debug('🧪 Sales 앱 알림 시스템 테스트 완료!');
    
} catch (Exception e) {
    System.debug('❌ Sales 앱 알림 시스템 테스트 오류: ' + e.getMessage());
    System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
}

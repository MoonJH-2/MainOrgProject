// Order 00000151 개선된 알림 시스템 종합 테스트
System.debug('🎯 =====개선된 알림 시스템 종합 테스트=====');

try {
    // 1. Order 00000151 정보 조회
    System.debug('');
    System.debug('📋 1단계: Order 00000151 정보 확인');
    
    List<Order> orders = [
        SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate,
               AccountId, Account.Name, OwnerId, Owner.Name, Owner.Email,
               Slack_Channel_Name__c, Slack_Notification_Status__c,
               CreatedDate, CreatedBy.Name, ActivatedDate, ActivatedBy.Name
        FROM Order 
        WHERE OrderNumber = '00000151'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000151를 찾을 수 없습니다.');
        return;
    }
    
    Order order = orders[0];
    System.debug('✅ Order 정보 확인 완료:');
    System.debug('   - OrderNumber: ' + order.OrderNumber);
    System.debug('   - Account: ' + order.Account.Name);
    System.debug('   - Amount: ₩' + order.TotalAmount.format());
    System.debug('   - Status: ' + order.Status);
    System.debug('   - Owner: ' + order.Owner.Name);
    System.debug('   - Created: ' + order.CreatedDate.format());
    System.debug('   - Activated: ' + order.ActivatedDate.format());
    
    // 2. CustomNotificationType 설정 확인
    System.debug('');
    System.debug('🔧 2단계: CustomNotificationType 설정 확인');
    
    List<CustomNotificationType> salesTypes = [
        SELECT Id, DeveloperName, MasterLabel, Description
        FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (salesTypes.isEmpty()) {
        System.debug('❌ Sales_Order_Notification이 설정되지 않았습니다!');
        
        // 대안으로 사용할 수 있는 CustomNotificationType 찾기
        List<CustomNotificationType> availableTypes = [
            SELECT Id, DeveloperName, MasterLabel
            FROM CustomNotificationType
            LIMIT 3
        ];
        
        if (!availableTypes.isEmpty()) {
            System.debug('📋 사용 가능한 대안 CustomNotificationType:');
            for (CustomNotificationType type : availableTypes) {
                System.debug('   • ' + type.MasterLabel + ' (' + type.DeveloperName + ')');
            }
            
            // 첫 번째 타입으로 임시 테스트
            CustomNotificationType tempType = availableTypes[0];
            System.debug('⚠️ 임시로 ' + tempType.MasterLabel + ' 사용하여 테스트');
            
            try {
                Set<String> recipients = new Set<String>();
                recipients.add(UserInfo.getUserId());
                recipients.add(order.OwnerId);
                
                String title = '🧪 임시 테스트 알림';
                String body = 'Order ' + order.OrderNumber + ' 알림 시스템 테스트';
                
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(title);
                notification.setBody(body);
                notification.setNotificationTypeId(tempType.Id);
                notification.setTargetId(order.Id);
                notification.send(recipients);
                
                System.debug('✅ 임시 알림 발송 성공');
                
            } catch (Exception tempEx) {
                System.debug('❌ 임시 알림 발송 실패: ' + tempEx.getMessage());
            }
        }
        
        System.debug('');
        System.debug('📝 해결 방법:');
        System.debug('Setup > Custom Notification Types에서 다음과 같이 생성:');
        System.debug('- Name: Sales Order Notification');
        System.debug('- API Name: Sales_Order_Notification');
        System.debug('- Description: Order 생성, 연체, Slack 채널 알림');
        System.debug('- Channel: Desktop and Mobile');
        
        return;
    }
    
    CustomNotificationType salesType = salesTypes[0];
    System.debug('✅ CustomNotificationType 설정 확인: ' + salesType.MasterLabel);
    
    // 3. 개선된 Order 생성 알림 테스트
    System.debug('');
    System.debug('🎉 3단계: 개선된 Order 생성 알림 테스트');
    
    try {
        List<Order> orderList = new List<Order>{order};
        OrderNotificationService.notifyOrderCreated(orderList);
        System.debug('✅ OrderNotificationService.notifyOrderCreated() 실행 완료');
        
    } catch (Exception orderEx) {
        System.debug('❌ Order 생성 알림 실패: ' + orderEx.getMessage());
        System.debug('❌ 스택 트레이스: ' + orderEx.getStackTraceString());
    }
    
    // 4. 연체 PaymentStatus 확인 및 알림 테스트
    System.debug('');
    System.debug('🚨 4단계: 연체 알림 테스트');
    
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
               Order__c, Order__r.Account.Name, Order__r.OrderNumber
        FROM PaymentStatus__c 
        WHERE Order__c = :order.Id
        AND Status__c = '연체'
    ];
    
    System.debug('📊 연체 건수: ' + overduePayments.size() + '건');
    
    if (!overduePayments.isEmpty()) {
        try {
            OrderNotificationService.notifyOverduePayments(overduePayments);
            System.debug('✅ 연체 알림 발송 완료');
            
            for (PaymentStatus__c payment : overduePayments) {
                Integer overdueDays = payment.DueDate__c.daysBetween(Date.today());
                System.debug('   🚨 ' + payment.InstallmentNumber__c + '차: 연체 ' + overdueDays + '일');
            }
            
        } catch (Exception overdueEx) {
            System.debug('❌ 연체 알림 실패: ' + overdueEx.getMessage());
        }
    } else {
        System.debug('ℹ️ 현재 연체 건이 없습니다.');
        
        // 테스트를 위해 1차 PaymentStatus를 연체로 변경
        List<PaymentStatus__c> firstPayments = [
            SELECT Id, Status__c, InstallmentNumber__c
            FROM PaymentStatus__c 
            WHERE Order__c = :order.Id
            AND InstallmentNumber__c = 1
            LIMIT 1
        ];
        
        if (!firstPayments.isEmpty() && firstPayments[0].Status__c != '연체') {
            System.debug('🧪 테스트를 위해 1차 납부를 연체로 변경');
            
            PaymentStatus__c firstPayment = firstPayments[0];
            String oldStatus = firstPayment.Status__c;
            firstPayment.Status__c = '연체';
            
            try {
                update firstPayment;
                System.debug('✅ PaymentStatus 업데이트: ' + oldStatus + ' → 연체');
                System.debug('   📡 PaymentStatusTriggerHandler가 자동으로 연체 알림 발송');
                
            } catch (Exception updateEx) {
                System.debug('❌ PaymentStatus 업데이트 실패: ' + updateEx.getMessage());
            }
        }
    }
    
    // 5. Slack 채널 생성 알림 테스트
    System.debug('');
    System.debug('📢 5단계: Slack 채널 생성 알림 테스트');
    
    if (String.isNotBlank(order.Slack_Channel_Name__c)) {
        try {
            // Slack_Notification_Status__c 업데이트
            Order updateOrder = new Order(Id = order.Id);
            updateOrder.Slack_Notification_Status__c = 'Created';
            update updateOrder;
            
            System.debug('✅ Slack_Notification_Status__c 업데이트: Created');
            
            // Slack 채널 생성 알림 발송
            Order updatedOrder = [
                SELECT Id, OrderNumber, Slack_Channel_Name__c, Slack_Notification_Status__c
                FROM Order 
                WHERE Id = :order.Id
            ];
            
            List<Order> slackOrders = new List<Order>{updatedOrder};
            OrderNotificationService.notifySlackChannelCreated(slackOrders);
            
            System.debug('✅ Slack 채널 생성 알림 발송 완료');
            System.debug('   📢 채널명: #' + order.Slack_Channel_Name__c);
            
        } catch (Exception slackEx) {
            System.debug('❌ Slack 채널 알림 실패: ' + slackEx.getMessage());
        }
    } else {
        System.debug('ℹ️ Slack 채널이 설정되지 않았습니다.');
    }
    
    // 6. 수신자 정보 확인
    System.debug('');
    System.debug('👥 6단계: 알림 수신자 정보');
    
    User currentUser = [
        SELECT Id, Name, Email, ManagerId, Manager.Name, Manager.Email
        FROM User 
        WHERE Id = :UserInfo.getUserId()
    ];
    
    System.debug('📧 알림 수신자 목록:');
    System.debug('   1. 현재 사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
    System.debug('   2. Order Owner: ' + order.Owner.Name + ' (' + order.Owner.Email + ')');
    
    if (currentUser.ManagerId != null) {
        System.debug('   3. Manager: ' + currentUser.Manager.Name + ' (' + currentUser.Manager.Email + ')');
    }
    
    // 시스템 관리자 확인
    List<User> adminUsers = [
        SELECT Id, Name, Email
        FROM User 
        WHERE Profile.Name IN ('시스템 관리자', 'System Administrator') 
        AND IsActive = true
        LIMIT 3
    ];
    
    System.debug('   4. 시스템 관리자: ' + adminUsers.size() + '명');
    for (User admin : adminUsers) {
        System.debug('      • ' + admin.Name + ' (' + admin.Email + ')');
    }
    
    // 7. 최종 확인 방법
    System.debug('');
    System.debug('🔔 7단계: 최종 확인 방법');
    System.debug('');
    System.debug('즉시 확인:');
    System.debug('1. Salesforce 상단 🔔 벨 아이콘 클릭');
    System.debug('2. 다음 알림들이 표시되는지 확인:');
    System.debug('   • 🎉 새 주문 생성: ' + order.Account.Name + ' - Order ' + order.OrderNumber);
    System.debug('   • 🚨 납부 연체 발생: (연체 건이 있는 경우)');
    System.debug('   • 📢 Slack 채널 생성 완료: (Slack 채널이 있는 경우)');
    System.debug('3. 알림 클릭 시 Order 00000151로 이동하는지 확인');
    System.debug('');
    System.debug('Mobile 확인:');
    System.debug('1. Mobile Salesforce 앱에서 푸시 알림 확인');
    System.debug('2. 알림 터치 시 Order 상세 페이지로 이동 확인');
    
    // 8. 문제 해결 가이드
    System.debug('');
    System.debug('🛠️ 8단계: 문제 해결 가이드');
    System.debug('');
    System.debug('알림이 보이지 않는 경우:');
    System.debug('1. 브라우저 알림 권한 확인 (Chrome: 설정 > 개인정보 및 보안 > 사이트 설정 > 알림)');
    System.debug('2. Salesforce 도메인 알림 허용 확인');
    System.debug('3. CustomNotificationType 설정 재확인');
    System.debug('4. 사용자 Profile의 Custom Notification 권한 확인');
    
} catch (Exception e) {
    System.debug('❌ 종합 테스트 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
    System.debug('   스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('🎯 =====개선된 알림 시스템 종합 테스트 완료=====');
System.debug('📢 지금 바로 상단 벨 아이콘을 확인해보세요!');

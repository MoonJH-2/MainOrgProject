// 실제 Sales 앱 알림 동작을 위한 설정 확인 및 실행 스크립트
System.debug('🚀 =====실제 Sales 앱 알림 동작 확인=====');

try {
    // 1. CustomNotificationType 설정 상태 확인
    System.debug('');
    System.debug('🔧 1단계: CustomNotificationType 설정 확인');
    
    List<CustomNotificationType> salesNotificationTypes = [
        SELECT Id, DeveloperName, MasterLabel, Description
        FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (salesNotificationTypes.isEmpty()) {
        System.debug('❌ Sales_Order_Notification이 설정되지 않았습니다!');
        System.debug('📋 먼저 Setup에서 다음과 같이 생성해주세요:');
        System.debug('   - Name: Sales Order Notification');
        System.debug('   - API Name: Sales_Order_Notification');
        System.debug('   - Description: Order 관련 실시간 알림');
        System.debug('   - Channel: Desktop and Mobile');
        System.debug('⚠️ 이 설정 없이는 실제 알림이 발송되지 않습니다.');
        return;
    }
    
    CustomNotificationType salesType = salesNotificationTypes[0];
    System.debug('✅ Sales_Order_Notification 설정됨: ' + salesType.MasterLabel);
    
    // 2. Order 00000149 실제 상태 확인
    System.debug('');
    System.debug('📊 2단계: Order 00000149 실제 상태 확인');
    
    List<Order> orders = [
        SELECT Id, OrderNumber, Status, TotalAmount, AccountId, Account.Name,
               OwnerId, Owner.Name, Owner.Email, Owner.ManagerId,
               Slack_Channel_Name__c, Slack_Notification_Status__c,
               CreatedDate, LastModifiedDate
        FROM Order 
        WHERE OrderNumber = '00000149'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000149를 찾을 수 없습니다.');
        return;
    }
    
    Order order = orders[0];
    System.debug('✅ Order 정보:');
    System.debug('   - ID: ' + order.Id);
    System.debug('   - Status: ' + order.Status);
    System.debug('   - Account: ' + order.Account.Name);
    System.debug('   - Owner: ' + order.Owner.Name);
    System.debug('   - Slack Channel: ' + order.Slack_Channel_Name__c);
    
    // 3. 연체 상태 PaymentStatus 확인
    System.debug('');
    System.debug('💰 3단계: 연체 PaymentStatus 확인');
    
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
               Order__c, Order__r.Account.Name, Order__r.OrderNumber
        FROM PaymentStatus__c 
        WHERE Order__c = :order.Id
        AND Status__c = '연체'
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('📋 연체 건수: ' + overduePayments.size() + '건');
    for (PaymentStatus__c payment : overduePayments) {
        Integer overdueDays = payment.DueDate__c.daysBetween(Date.today());
        System.debug('   🚨 ' + payment.InstallmentNumber__c + '차: ₩' + 
                    payment.Amount__c.format() + ' (연체 ' + overdueDays + '일)');
    }
    
    // 4. 실제 알림 수신자 확인
    System.debug('');
    System.debug('👥 4단계: 실제 알림 수신자 확인');
    
    Set<String> recipients = new Set<String>();
    
    // 현재 사용자
    User currentUser = [
        SELECT Id, Name, Email, ManagerId, Manager.Name
        FROM User 
        WHERE Id = :UserInfo.getUserId()
    ];
    recipients.add(currentUser.Id);
    System.debug('   📧 현재 사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
    
    // Order Owner
    recipients.add(order.OwnerId);
    System.debug('   👤 Order Owner: ' + order.Owner.Name + ' (' + order.Owner.Email + ')');
    
    // Manager들
    if (currentUser.ManagerId != null) {
        recipients.add(currentUser.ManagerId);
        System.debug('   👔 현재 사용자 Manager: ' + currentUser.Manager.Name);
    }
    
    if (order.Owner.ManagerId != null) {
        recipients.add(order.Owner.ManagerId);
        System.debug('   👔 Order Owner Manager 포함');
    }
    
    // 시스템 관리자
    List<User> adminUsers = [
        SELECT Id, Name, Email
        FROM User 
        WHERE Profile.Name IN ('시스템 관리자', 'System Administrator') 
        AND IsActive = true
        LIMIT 3
    ];
    
    for (User admin : adminUsers) {
        recipients.add(admin.Id);
        System.debug('   🔐 시스템 관리자: ' + admin.Name);
    }
    
    System.debug('📊 총 수신자: ' + recipients.size() + '명');
    
    // 5. 실제 Sales 앱 알림 발송
    System.debug('');
    System.debug('🚀 5단계: 실제 Sales 앱 알림 발송');
    
    if (!overduePayments.isEmpty()) {
        System.debug('');
        System.debug('🚨 연체 알림 발송 중...');
        
        try {
            // 실제 연체 알림 발송
            OrderNotificationService.notifyOverduePayments(overduePayments);
            
            // 추가로 직접 알림도 발송
            for (PaymentStatus__c payment : overduePayments) {
                Integer overdueDays = payment.DueDate__c.daysBetween(Date.today());
                
                String title = '🚨 납부 연체 발생';
                String body = payment.Order__r.Account.Name + ' - ' + 
                             payment.InstallmentNumber__c + '차 납부 연체 (' + 
                             overdueDays + '일)';
                
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(title);
                notification.setBody(body);
                notification.setNotificationTypeId(salesType.Id);
                notification.setTargetId(payment.Order__c);
                notification.send(recipients);
                
                System.debug('✅ 연체 알림 발송: ' + title);
                System.debug('   📱 내용: ' + body);
                System.debug('   👥 수신자: ' + recipients.size() + '명');
            }
            
        } catch (Exception notifEx) {
            System.debug('❌ 연체 알림 발송 실패: ' + notifEx.getMessage());
        }
    }
    
    // 6. Order 생성 알림 재발송 (참고용)
    System.debug('');
    System.debug('🎉 Order 생성 알림 재발송 (참고용)');
    
    try {
        String title = '🎉 새 주문 생성';
        String body = order.Account.Name + ' - Order ' + order.OrderNumber + 
                     ' (₩' + order.TotalAmount.format() + ')';
        
        Messaging.CustomNotification orderNotification = new Messaging.CustomNotification();
        orderNotification.setTitle(title);
        orderNotification.setBody(body);
        orderNotification.setNotificationTypeId(salesType.Id);
        orderNotification.setTargetId(order.Id);
        orderNotification.send(recipients);
        
        System.debug('✅ Order 생성 알림 발송: ' + title);
        System.debug('   📱 내용: ' + body);
        
    } catch (Exception orderEx) {
        System.debug('❌ Order 생성 알림 발송 실패: ' + orderEx.getMessage());
    }
    
    // 7. Slack 채널 생성 알림 (해당되는 경우)
    if (String.isNotBlank(order.Slack_Channel_Name__c)) {
        System.debug('');
        System.debug('📢 Slack 채널 생성 알림 발송');
        
        try {
            String title = '📢 Slack 채널 생성 완료';
            String body = 'Order ' + order.OrderNumber + ' Salesforce 연동 채널 생성 (#' + 
                         order.Slack_Channel_Name__c + ')';
            
            Messaging.CustomNotification slackNotification = new Messaging.CustomNotification();
            slackNotification.setTitle(title);
            slackNotification.setBody(body);
            slackNotification.setNotificationTypeId(salesType.Id);
            slackNotification.setTargetId(order.Id);
            slackNotification.send(recipients);
            
            System.debug('✅ Slack 채널 알림 발송: ' + title);
            System.debug('   📱 내용: ' + body);
            
        } catch (Exception slackEx) {
            System.debug('❌ Slack 채널 알림 발송 실패: ' + slackEx.getMessage());
        }
    }
    
    // 8. 실제 확인 방법 안내
    System.debug('');
    System.debug('🔔 실제 Sales 앱 알림 확인 방법:');
    System.debug('1. Salesforce 상단의 🔔 벨 아이콘 클릭');
    System.debug('2. 방금 발송된 알림들이 표시되는지 확인');
    System.debug('3. 알림 클릭 시 해당 Order 레코드로 이동하는지 확인');
    System.debug('4. Mobile Salesforce 앱에서도 푸시 알림 확인 가능');
    
    System.debug('');
    System.debug('📱 Mobile 앱 알림 확인:');
    System.debug('1. Mobile Salesforce 앱 로그인');
    System.debug('2. 앱 알림 설정 활성화 확인');
    System.debug('3. 푸시 알림으로 수신되는지 확인');
    
    System.debug('');
    System.debug('⚡ 실시간 테스트 방법:');
    System.debug('1. PaymentStatus 레코드의 Status를 "미납"에서 "연체"로 변경');
    System.debug('2. 즉시 Sales 앱 알림이 발송되는지 확인');
    System.debug('3. 새 Order 생성 시 알림 발송 확인');
    
} catch (Exception e) {
    System.debug('❌ 실제 알림 테스트 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
    System.debug('   스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('🎯 =====실제 Sales 앱 알림 확인 완료=====');
System.debug('📢 상단 벨 아이콘을 지금 확인해보세요!');

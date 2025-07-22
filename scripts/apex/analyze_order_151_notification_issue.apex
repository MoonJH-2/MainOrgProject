// Order 00000151 Sales 앱 알림 문제 분석 스크립트
System.debug('🔍 =====Order 00000151 알림 문제 분석=====');

try {
    // 1. Order 00000151 상세 정보 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate,
               AccountId, Account.Name, OwnerId, Owner.Name, Owner.Email,
               Slack_Channel_Name__c, Slack_Notification_Status__c,
               CreatedDate, CreatedById, CreatedBy.Name,
               LastModifiedDate, LastModifiedById, LastModifiedBy.Name,
               ActivatedDate, ActivatedById, ActivatedBy.Name
        FROM Order 
        WHERE OrderNumber = '00000151'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000151를 찾을 수 없습니다.');
        return;
    }
    
    Order order = orders[0];
    System.debug('');
    System.debug('📋 Order 00000151 기본 정보:');
    System.debug('   ID: ' + order.Id);
    System.debug('   OrderNumber: ' + order.OrderNumber);
    System.debug('   Status: ' + order.Status);
    System.debug('   Account: ' + order.Account.Name);
    System.debug('   Owner: ' + order.Owner.Name);
    System.debug('   Total Amount: ₩' + order.TotalAmount.format());
    System.debug('   Created: ' + order.CreatedDate + ' by ' + order.CreatedBy.Name);
    System.debug('   Activated: ' + order.ActivatedDate + ' by ' + order.ActivatedBy.Name);
    System.debug('   Slack Channel: ' + order.Slack_Channel_Name__c);
    System.debug('   Slack Status: ' + order.Slack_Notification_Status__c);
    
    // 2. CustomNotificationType 설정 확인
    System.debug('');
    System.debug('🔧 CustomNotificationType 설정 확인:');
    
    List<CustomNotificationType> salesTypes = [
        SELECT Id, DeveloperName, MasterLabel, Description
        FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (salesTypes.isEmpty()) {
        System.debug('❌ Sales_Order_Notification이 설정되지 않았습니다!');
        System.debug('   이것이 알림이 오지 않는 주요 원인입니다.');
        System.debug('   Setup > Custom Notification Types에서 생성 필요');
        
        // 즉시 해결을 위한 테스트 알림 발송 시도
        System.debug('');
        System.debug('🧪 대안: 기존 CustomNotificationType으로 테스트 알림 발송');
        
        List<CustomNotificationType> existingTypes = [
            SELECT Id, DeveloperName, MasterLabel
            FROM CustomNotificationType
            LIMIT 5
        ];
        
        System.debug('   사용 가능한 CustomNotificationType: ' + existingTypes.size() + '개');
        for (CustomNotificationType type : existingTypes) {
            System.debug('     • ' + type.MasterLabel + ' (' + type.DeveloperName + ')');
        }
        
        return;
    }
    
    CustomNotificationType salesType = salesTypes[0];
    System.debug('✅ Sales_Order_Notification 설정됨: ' + salesType.MasterLabel);
    
    // 3. OrderTriggerHandler 동작 확인
    System.debug('');
    System.debug('🔄 OrderTriggerHandler 동작 분석:');
    
    // Order 생성 시점과 활성화 시점 확인
    Datetime createdTime = order.CreatedDate;
    Datetime activatedTime = order.ActivatedDate;
    
    System.debug('   생성 시간: ' + createdTime.format());
    System.debug('   활성화 시간: ' + activatedTime.format());
    
    Long timeDiff = activatedTime.getTime() - createdTime.getTime();
    Long secondsDiff = timeDiff / 1000;
    
    System.debug('   생성→활성화 간격: ' + secondsDiff + '초');
    
    if (secondsDiff < 5) {
        System.debug('   ⚠️ 생성과 활성화가 거의 동시에 발생 (트리거 중복 가능성)');
    }
    
    // 4. 알림 수신자 확인
    System.debug('');
    System.debug('👥 알림 수신자 분석:');
    
    User currentUser = [
        SELECT Id, Name, Email, ManagerId, Manager.Name, Manager.Email
        FROM User 
        WHERE Id = :UserInfo.getUserId()
    ];
    
    Set<String> expectedRecipients = new Set<String>();
    expectedRecipients.add(order.OwnerId);
    expectedRecipients.add(order.CreatedById);
    expectedRecipients.add(UserInfo.getUserId());
    
    if (currentUser.ManagerId != null) {
        expectedRecipients.add(currentUser.ManagerId);
    }
    
    System.debug('   Order Owner: ' + order.Owner.Name + ' (' + order.Owner.Email + ')');
    System.debug('   Order Creator: ' + order.CreatedBy.Name);
    System.debug('   현재 사용자: ' + currentUser.Name);
    if (currentUser.ManagerId != null) {
        System.debug('   Manager: ' + currentUser.Manager.Name);
    }
    System.debug('   예상 수신자 수: ' + expectedRecipients.size() + '명');
    
    // 5. PaymentStatus 연체 상황 확인
    System.debug('');
    System.debug('💰 PaymentStatus 연체 상황:');
    
    List<PaymentStatus__c> payments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
               CreatedDate, LastModifiedDate
        FROM PaymentStatus__c 
        WHERE Order__c = :order.Id
        ORDER BY InstallmentNumber__c ASC
    ];
    
    Integer overdueCount = 0;
    for (PaymentStatus__c payment : payments) {
        String statusIcon = payment.Status__c == '연체' ? '🚨' : 
                           payment.Status__c == '완납' ? '✅' : '⏳';
        
        System.debug('   ' + statusIcon + ' ' + payment.InstallmentNumber__c + '차: ' + 
                    payment.Status__c + ' (due: ' + payment.DueDate__c.format() + ')');
        
        if (payment.Status__c == '연체') {
            overdueCount++;
        }
    }
    
    System.debug('   📊 현재 연체 건수: ' + overdueCount + '건');
    
    // 6. 실제 알림 발송 테스트
    System.debug('');
    System.debug('🚀 실제 알림 발송 테스트:');
    
    try {
        // Order 생성 알림 수동 발송
        String title = '🎉 새 주문 생성 (수동 테스트)';
        String body = order.Account.Name + ' - Order ' + order.OrderNumber + 
                     ' (₩' + order.TotalAmount.format() + ')';
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(salesType.Id);
        notification.setTargetId(order.Id);
        notification.send(expectedRecipients);
        
        System.debug('✅ 수동 알림 발송 성공');
        System.debug('   제목: ' + title);
        System.debug('   내용: ' + body);
        System.debug('   수신자: ' + expectedRecipients.size() + '명');
        
    } catch (Exception notifEx) {
        System.debug('❌ 수동 알림 발송 실패: ' + notifEx.getMessage());
    }
    
    // 7. OrderTriggerHandler 수동 호출 테스트
    System.debug('');
    System.debug('🔄 OrderTriggerHandler 수동 테스트:');
    
    try {
        List<Order> testOrderList = new List<Order>{order};
        OrderNotificationService.notifyOrderCreated(testOrderList);
        System.debug('✅ OrderNotificationService.notifyOrderCreated() 수동 실행 완료');
        
    } catch (Exception triggerEx) {
        System.debug('❌ OrderTriggerHandler 수동 실행 실패: ' + triggerEx.getMessage());
    }
    
    // 8. Slack 채널 알림 테스트 (해당되는 경우)
    if (String.isNotBlank(order.Slack_Channel_Name__c)) {
        System.debug('');
        System.debug('📢 Slack 채널 알림 테스트:');
        
        try {
            // Slack_Notification_Status__c를 'Created'로 설정
            Order updateOrder = new Order(Id = order.Id);
            updateOrder.Slack_Notification_Status__c = 'Created';
            update updateOrder;
            
            System.debug('✅ Slack_Notification_Status__c를 Created로 업데이트');
            
            List<Order> slackTestList = new List<Order>{updateOrder};
            OrderNotificationService.notifySlackChannelCreated(slackTestList);
            System.debug('✅ Slack 채널 생성 알림 수동 실행 완료');
            
        } catch (Exception slackEx) {
            System.debug('❌ Slack 채널 알림 테스트 실패: ' + slackEx.getMessage());
        }
    }
    
    // 9. 문제 진단 및 해결방안
    System.debug('');
    System.debug('🔍 문제 진단 결과:');
    
    if (salesTypes.isEmpty()) {
        System.debug('❌ 주요 문제: CustomNotificationType 미설정');
        System.debug('   해결방안: Setup에서 Sales_Order_Notification 생성');
    } else if (secondsDiff < 5) {
        System.debug('⚠️ 의심 문제: 생성과 활성화가 거의 동시 발생');
        System.debug('   해결방안: 트리거 로직 개선 필요');
    } else {
        System.debug('✅ 기본 설정은 정상적임');
        System.debug('   추가 확인: 브라우저 알림 권한, 사용자 권한');
    }
    
    // 10. 즉시 확인 방법
    System.debug('');
    System.debug('🔔 지금 즉시 확인:');
    System.debug('1. Salesforce 상단 🔔 벨 아이콘 클릭');
    System.debug('2. 방금 발송된 "🎉 새 주문 생성 (수동 테스트)" 알림 확인');
    System.debug('3. 알림이 보이면 시스템은 정상, 트리거 문제');
    System.debug('4. 알림이 안 보이면 CustomNotificationType 설정 문제');
    
} catch (Exception e) {
    System.debug('❌ 분석 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
    System.debug('   스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('✅ =====Order 00000151 알림 문제 분석 완료=====');

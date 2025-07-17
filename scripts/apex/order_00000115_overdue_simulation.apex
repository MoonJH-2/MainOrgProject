// Order 00000115 연체 시뮬레이션 테스트
System.debug('🚨 =====Order 00000115 연체 시뮬레이션 테스트=====');

try {
    // 1. Order 00000115 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name
        FROM Order 
        WHERE OrderNumber = '00000115'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000115를 찾을 수 없습니다.');
        return;
    }
    
    Order targetOrder = orders[0];
    System.debug('📋 테스트 대상: ' + targetOrder.OrderNumber + ' (' + targetOrder.Account.Name + ')');
    
    // 2. 2차 납부를 과거 날짜로 변경하여 연체 상황 시뮬레이션
    List<PaymentStatus__c> secondPayments = [
        SELECT Id, InstallmentNumber__c, DueDate__c, Status__c, Amount__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        AND InstallmentNumber__c = 2
        LIMIT 1
    ];
    
    if (secondPayments.isEmpty()) {
        System.debug('❌ 2차 납부를 찾을 수 없습니다.');
        return;
    }
    
    PaymentStatus__c secondPayment = secondPayments[0];
    System.debug('📊 2차 납부 원래 정보:');
    System.debug('   • 예정일: ' + secondPayment.DueDate__c.format());
    System.debug('   • 상태: ' + secondPayment.Status__c);
    System.debug('   • 금액: ₩' + secondPayment.Amount__c.format());
    
    // 2차 납부를 3일 전으로 변경 (연체 상황 만들기)
    Date pastDueDate = Date.today().addDays(-3);
    secondPayment.DueDate__c = pastDueDate;
    secondPayment.Status__c = '미납'; // 연체 상태로 변경
    
    update secondPayment;
    System.debug('✅ 2차 납부를 연체 상태로 변경 완료');
    System.debug('   • 새 예정일: ' + pastDueDate.format() + ' (3일 전)');
    System.debug('   • 새 상태: 미납');
    
    // 3. 연체 알림 생성 및 발송 테스트
    System.debug('🔔 연체 알림 시스템 테스트 중...');
    
    Payment_Notification__c notification = new Payment_Notification__c();
    notification.PaymentStatus__c = secondPayment.Id;
    notification.NotificationType__c = '연체 알림';
    notification.NotificationChannel__c = 'Salesforce';
    notification.NotificationStatus__c = 'Pending';
    notification.ScheduledDateTime__c = DateTime.now();
    
    insert notification;
    System.debug('✅ 연체 알림 레코드 생성: ' + notification.Id);
    
    // 관계 필드와 함께 다시 조회
    Payment_Notification__c fullNotification = [
        SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
               PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.Account.Id,
               PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c,
               PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c,
               NotificationType__c, NotificationChannel__c
        FROM Payment_Notification__c 
        WHERE Id = :notification.Id
    ];
    
    // 4. 알림 발송 테스트
    System.debug('📮 다중 채널 알림 발송 테스트...');
    
    // 4-1. Salesforce 알림 (Task + Chatter + Custom Notification)
    Boolean salesforceResult = PaymentNotificationService.sendSalesforceNotification(fullNotification);
    System.debug('   🔔 Salesforce 알림: ' + (salesforceResult ? '✅ 성공' : '❌ 실패'));
    
    // 4-2. 이메일 알림 (고객 + 관리자)
    Boolean emailResult = PaymentNotificationService.sendEmailNotification(fullNotification);
    System.debug('   📧 이메일 알림: ' + (emailResult ? '✅ 성공' : '❌ 실패'));
    
    // 5. 생성된 Task 확인
    System.debug('📝 새로 생성된 Task 확인:');
    List<Task> newTasks = [
        SELECT Id, Subject, Priority, Status, ActivityDate, CreatedDate
        FROM Task 
        WHERE WhatId = :targetOrder.Id
        AND CreatedDate = TODAY
        AND Subject LIKE '%2차%'
        ORDER BY CreatedDate DESC
        LIMIT 3
    ];
    
    System.debug('   2차 관련 새 Task 수: ' + newTasks.size() + '개');
    for (Task task : newTasks) {
        System.debug('   • ' + task.Subject + ' (우선순위: ' + task.Priority + ', 상태: ' + task.Status + ')');
        System.debug('     활동일: ' + (task.ActivityDate != null ? task.ActivityDate.format() : '미설정'));
    }
    
    // 6. 전체 Task 현황 확인
    List<Task> allTasks = [
        SELECT Id, Subject, Priority, Status, ActivityDate, CreatedDate
        FROM Task 
        WHERE WhatId = :targetOrder.Id
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
    
    System.debug('📋 Order 00000115 전체 Task 현황: ' + allTasks.size() + '개');
    for (Task task : allTasks) {
        String createdToday = task.CreatedDate.date() == Date.today() ? ' [오늘]' : '';
        System.debug('   • ' + task.Subject + ' (' + task.Priority + ')' + createdToday);
    }
    
    // 7. 테스트 정리 - 원래 상태로 복구
    System.debug('🔄 테스트 정리 중...');
    secondPayment.DueDate__c = Date.newInstance(2025, 8, 14); // 원래 날짜로 복구
    secondPayment.Status__c = '예정'; // 원래 상태로 복구
    update secondPayment;
    System.debug('✅ 2차 납부 원래 상태로 복구 완료');
    
    // 8. 테스트 결과 요약
    System.debug('');
    System.debug('📊 =====연체 시뮬레이션 테스트 결과=====');
    System.debug('• 연체 상황 생성: ✅ 성공 (2차 납부 3일 연체)');
    System.debug('• 알림 레코드 생성: ✅ 성공');
    System.debug('• Salesforce 알림: ' + (salesforceResult ? '✅ 성공' : '❌ 실패'));
    System.debug('• 이메일 알림: ' + (emailResult ? '✅ 성공' : '❌ 실패'));
    System.debug('• Task 생성: ' + newTasks.size() + '개 생성');
    System.debug('• 테스트 정리: ✅ 완료');
    
    System.debug('');
    System.debug('🎯 Order 00000115 Activity Timeline 확인 항목:');
    System.debug('1. "연체 알림 - 0714TEST 2차" Task 확인');
    System.debug('2. 우선순위 High로 설정되었는지 확인');
    System.debug('3. Upcoming & Overdue 섹션에 표시되는지 확인');
    System.debug('4. Task 설명에 연체 정보가 포함되어 있는지 확인');
    
    System.debug('✅ =====Order 00000115 연체 시뮬레이션 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 연체 시뮬레이션 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

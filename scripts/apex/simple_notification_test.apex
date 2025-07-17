// 간단한 알림 시스템 테스트
System.debug('🚀 =====간단 알림 테스트 시작=====');

try {
    // 1. 연체된 PaymentStatus 조회
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber, 
               InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Status__c != '완납' 
        AND DueDate__c < TODAY
        ORDER BY DueDate__c ASC
        LIMIT 1
    ];
    
    if (overduePayments.isEmpty()) {
        System.debug('❌ 테스트할 연체 데이터가 없습니다.');
        return;
    }
    
    PaymentStatus__c payment = overduePayments[0];
    System.debug('📊 테스트 대상: ' + payment.Order__r.Account.Name + ' ' + payment.InstallmentNumber__c + '차');
    
    // 2. Payment_Notification__c 레코드 생성
    Payment_Notification__c notification = new Payment_Notification__c();
    notification.PaymentStatus__c = payment.Id;
    notification.NotificationType__c = '연체 알림';
    notification.NotificationChannel__c = 'Salesforce';
    notification.NotificationStatus__c = 'Pending';
    notification.ScheduledDateTime__c = DateTime.now();
    
    insert notification;
    System.debug('✅ 알림 레코드 생성: ' + notification.Id);
    
    // 3. 관계 필드와 함께 다시 조회
    Payment_Notification__c fullNotification = [
        SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
               PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.Account.Id,
               PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c,
               PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c,
               NotificationType__c, NotificationChannel__c
        FROM Payment_Notification__c 
        WHERE Id = :notification.Id
    ];
    
    // 4. Salesforce 알림 테스트
    System.debug('🔔 Salesforce 알림 발송 중...');
    Boolean result = PaymentNotificationService.sendSalesforceNotification(fullNotification);
    System.debug('   결과: ' + (result ? '✅ 성공' : '❌ 실패'));
    
    // 5. 생성된 Task 확인
    List<Task> createdTasks = [
        SELECT Id, Subject, WhatId, Priority, Status, ActivityDate
        FROM Task 
        WHERE WhatId = :payment.Order__c
        AND CreatedDate = TODAY
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    System.debug('📝 생성된 Task: ' + createdTasks.size() + '개');
    for (Task task : createdTasks) {
        System.debug('   • ' + task.Subject + ' (우선순위: ' + task.Priority + ')');
    }
    
    // 6. Chatter 포스트 확인
    List<FeedItem> posts = [
        SELECT Id, Body
        FROM FeedItem 
        WHERE ParentId = :payment.Order__c
        AND CreatedDate = TODAY
        ORDER BY CreatedDate DESC
        LIMIT 3
    ];
    
    System.debug('💬 생성된 Chatter 포스트: ' + posts.size() + '개');
    for (FeedItem post : posts) {
        System.debug('   • ' + post.Body.substring(0, Math.min(50, post.Body.length())) + '...');
    }
    
    System.debug('✅ =====간단 알림 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

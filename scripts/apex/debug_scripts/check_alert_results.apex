// 연체 알림 처리 결과 확인
System.debug('=== 연체 알림 처리 결과 확인 ===');

// 1. Order 00000115 조회
List<Order> orders = [SELECT Id, OrderNumber FROM Order WHERE OrderNumber = '00000115' LIMIT 1];

if (!orders.isEmpty()) {
    Id orderId = orders[0].Id;
    System.debug('Order ID: ' + orderId);
    
    // 2. Order에 연결된 Task 확인
    List<Task> orderTasks = [
        SELECT Id, Subject, Status, Priority, ActivityDate, Description, CreatedDate
        FROM Task 
        WHERE WhatId = :orderId
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
    
    System.debug('Order에 연결된 Task 수: ' + orderTasks.size());
    for (Task t : orderTasks) {
        System.debug('Task: ' + t.Subject + ' (상태: ' + t.Status + ', 우선순위: ' + t.Priority + ')');
        System.debug('     생성일: ' + t.CreatedDate + ', 활동일: ' + t.ActivityDate);
    }
    
    // 3. Order의 Chatter Feed 확인
    List<FeedItem> feeds = [
        SELECT Id, Body, Type, CreatedDate, CreatedBy.Name
        FROM FeedItem 
        WHERE ParentId = :orderId
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    System.debug('Order Chatter Feed 수: ' + feeds.size());
    for (FeedItem feed : feeds) {
        System.debug('Feed: ' + feed.Body.left(50) + '... (by ' + feed.CreatedBy.Name + ')');
    }
    
    // 4. Payment_Notification__c 레코드 확인
    List<Payment_Notification__c> notifications = [
        SELECT Id, NotificationType__c, NotificationChannel__c, NotificationStatus__c, 
               SentDateTime__c, ErrorMessage__c, PaymentStatus__r.InstallmentNumber__c
        FROM Payment_Notification__c 
        WHERE PaymentStatus__r.Order__c = :orderId
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
    
    System.debug('알림 레코드 수: ' + notifications.size());
    for (Payment_Notification__c notif : notifications) {
        System.debug('알림: ' + notif.NotificationType__c + ' (' + notif.NotificationChannel__c + ') - ' + 
                    notif.PaymentStatus__r.InstallmentNumber__c + '차');
        System.debug('     상태: ' + notif.NotificationStatus__c + 
                    (notif.ErrorMessage__c != null ? ', 오류: ' + notif.ErrorMessage__c : ''));
    }
    
    // 5. 연체된 PaymentStatus 확인
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, InstallmentNumber__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :orderId
        AND Status__c = '미납'
        AND DueDate__c < TODAY
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('연체된 PaymentStatus 수: ' + overduePayments.size());
    for (PaymentStatus__c ps : overduePayments) {
        System.debug('연체: ' + ps.InstallmentNumber__c + '차 (납기일: ' + ps.DueDate__c + ')');
    }
    
} else {
    System.debug('Order 00000115를 찾을 수 없습니다.');
}

System.debug('=== 확인 완료 ===');

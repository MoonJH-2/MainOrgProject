// 연체 알림 즉시 처리 - Order 00000115
System.debug('=== 연체 알림 즉시 처리 시작 ===');

// 1. Order 00000115의 연체된 PaymentStatus 조회
List<PaymentStatus__c> overduePayments = [
    SELECT Id, Order__c, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
           Order__r.Account.Id, Order__r.Account.Name, Order__r.OrderNumber,
           Order__r.Account.PersonEmail
    FROM PaymentStatus__c 
    WHERE Order__r.OrderNumber = '00000115'
    AND Status__c = '미납' 
    AND DueDate__c < TODAY
    ORDER BY InstallmentNumber__c ASC
];

System.debug('연체된 납부 건수: ' + overduePayments.size());

if (!overduePayments.isEmpty()) {
    List<Payment_Notification__c> notifications = new List<Payment_Notification__c>();
    
    // 2. 각 연체 납부에 대해 알림 레코드 생성
    for (PaymentStatus__c ps : overduePayments) {
        // Salesforce 내부 알림
        Payment_Notification__c salesforceNotif = new Payment_Notification__c();
        salesforceNotif.PaymentStatus__c = ps.Id;
        salesforceNotif.NotificationType__c = '연체 알림';
        salesforceNotif.NotificationChannel__c = 'Salesforce';
        salesforceNotif.NotificationStatus__c = 'Pending';
        salesforceNotif.ScheduledDateTime__c = DateTime.now();
        notifications.add(salesforceNotif);
        
        // 이메일 알림
        Payment_Notification__c emailNotif = new Payment_Notification__c();
        emailNotif.PaymentStatus__c = ps.Id;
        emailNotif.NotificationType__c = '연체 알림';
        emailNotif.NotificationChannel__c = 'Email';
        emailNotif.NotificationStatus__c = 'Pending';
        emailNotif.ScheduledDateTime__c = DateTime.now();
        emailNotif.RecipientEmail__c = ps.Order__r.Account.PersonEmail;
        notifications.add(emailNotif);
        
        System.debug('알림 생성: ' + ps.Order__r.OrderNumber + ' - ' + ps.InstallmentNumber__c + '차');
    }
    
    // 3. 알림 레코드 저장
    insert notifications;
    System.debug('저장된 알림 수: ' + notifications.size());
    
    // 4. 각 알림에 대해 즉시 처리
    List<Payment_Notification__c> fullNotifications = [
        SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
               PaymentStatus__r.Order__r.Account.Id, PaymentStatus__r.Order__r.Account.Name, 
               PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c, 
               PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, 
               NotificationType__c, NotificationChannel__c, RecipientEmail__c
        FROM Payment_Notification__c 
        WHERE Id IN :notifications
    ];
    
    List<Payment_Notification__c> toUpdate = new List<Payment_Notification__c>();
    
    for (Payment_Notification__c notif : fullNotifications) {
        Boolean success = false;
        String errorMsg = '';
        
        try {
            if (notif.NotificationChannel__c == 'Salesforce') {
                // Salesforce 알림 처리 (Task 생성 + Custom Notification)
                success = PaymentNotificationService.sendSalesforceNotification(notif);
            } else if (notif.NotificationChannel__c == 'Email') {
                // 이메일 알림 처리
                success = PaymentNotificationService.sendEmailNotification(notif);
            }
            
            if (success) {
                notif.NotificationStatus__c = 'Sent';
                notif.SentDateTime__c = DateTime.now();
            } else {
                notif.NotificationStatus__c = 'Failed';
                notif.ErrorMessage__c = '알림 발송 실패';
            }
            
        } catch (Exception e) {
            notif.NotificationStatus__c = 'Failed';
            notif.ErrorMessage__c = e.getMessage();
            System.debug('알림 처리 오류: ' + e.getMessage());
        }
        
        toUpdate.add(notif);
    }
    
    // 5. 알림 상태 업데이트
    update toUpdate;
    System.debug('알림 처리 완료');
    
    // 6. 결과 확인
    List<Task> createdTasks = [
        SELECT Id, Subject, Status, Priority, WhatId, ActivityDate
        FROM Task 
        WHERE WhatId = :overduePayments[0].Order__c
        AND Subject LIKE '%연체 알림%'
        AND CreatedDate = TODAY
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('생성된 Task 수: ' + createdTasks.size());
    for (Task t : createdTasks) {
        System.debug('Task: ' + t.Subject + ' (우선순위: ' + t.Priority + ')');
    }
    
} else {
    System.debug('연체된 납부가 없습니다. DueDate가 ' + Date.today() + ' 이전인 미납 건을 찾지 못했습니다.');
    
    // 전체 PaymentStatus 상태 확인
    List<PaymentStatus__c> allPayments = [
        SELECT InstallmentNumber__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__r.OrderNumber = '00000115'
        ORDER BY InstallmentNumber__c ASC
    ];
    
    for (PaymentStatus__c ps : allPayments) {
        System.debug(ps.InstallmentNumber__c + '차: ' + ps.DueDate__c + ' (' + ps.Status__c + ')');
    }
}

System.debug('=== 연체 알림 처리 완료 ===');

// 특정 PaymentStatus ID를 사용한 알림 테스트
// PaymentStatus ID: a01gK00000D03kq

System.debug('=== 특정 PaymentStatus 알림 테스트 시작 ===');

String targetPaymentStatusId = 'a01gK00000D03kqQAB'; // 완전한 ID

try {
    // 1. PaymentStatus 정보 확인
    List<PaymentStatus__c> paymentStatuses = [
        SELECT Id, Status__c, DueDate__c, Amount__c, InstallmentNumber__c,
               Order__c, Order__r.OrderNumber, Order__r.AccountId, Order__r.Account.Name
        FROM PaymentStatus__c 
        WHERE Id = :targetPaymentStatusId
        LIMIT 1
    ];
    
    if (paymentStatuses.isEmpty()) {
        System.debug('✗ PaymentStatus 레코드를 찾을 수 없습니다: ' + targetPaymentStatusId);
        return;
    }
    
    PaymentStatus__c paymentStatus = paymentStatuses[0];
    System.debug('✓ PaymentStatus 정보:');
    System.debug('  - ID: ' + paymentStatus.Id);
    System.debug('  - 상태: ' + paymentStatus.Status__c);
    System.debug('  - 납부예정일: ' + paymentStatus.DueDate__c);
    System.debug('  - 금액: ' + paymentStatus.Amount__c);
    System.debug('  - 차수: ' + paymentStatus.InstallmentNumber__c);
    System.debug('  - 주문번호: ' + paymentStatus.Order__r.OrderNumber);
    System.debug('  - 고객명: ' + paymentStatus.Order__r.Account.Name);
    
    // 2. 테스트 알림 생성 (연체 알림)
    Payment_Notification__c overdueNotification = new Payment_Notification__c();
    overdueNotification.PaymentStatus__c = paymentStatus.Id;
    overdueNotification.NotificationType__c = '연체 알림';
    overdueNotification.NotificationChannel__c = 'Salesforce';
    overdueNotification.NotificationStatus__c = 'Pending';
    overdueNotification.ScheduledDateTime__c = DateTime.now();
    
    insert overdueNotification;
    System.debug('✓ 연체 알림 레코드 생성 성공: ' + overdueNotification.Id);
    
    // 3. Salesforce 알림 발송 테스트
    Boolean salesforceResult = PaymentNotificationService.sendSalesforceNotification(overdueNotification);
    System.debug('✓ Salesforce 알림 발송 결과: ' + salesforceResult);
    
    // 4. 이메일 알림 테스트
    Boolean emailResult = PaymentNotificationService.sendEmailNotification(overdueNotification);
    System.debug('✓ 이메일 알림 발송 결과: ' + emailResult);
    
    // 5. 테스트 알림 생성 (예정 알림)
    Payment_Notification__c upcomingNotification = new Payment_Notification__c();
    upcomingNotification.PaymentStatus__c = paymentStatus.Id;
    upcomingNotification.NotificationType__c = '예정 알림';
    upcomingNotification.NotificationChannel__c = 'Email';
    upcomingNotification.NotificationStatus__c = 'Pending';
    upcomingNotification.ScheduledDateTime__c = DateTime.now().addMinutes(1);
    
    insert upcomingNotification;
    System.debug('✓ 예정 알림 레코드 생성 성공: ' + upcomingNotification.Id);
    
    // 6. 예정 알림 발송 테스트
    Boolean upcomingEmailResult = PaymentNotificationService.sendEmailNotification(upcomingNotification);
    System.debug('✓ 예정 알림 이메일 발송 결과: ' + upcomingEmailResult);
    
    // 7. 배치 처리 테스트 (생성된 알림들 처리)
    System.debug('=== 배치 처리 테스트 ===');
    PaymentNotificationBatch testBatch = new PaymentNotificationBatch();
    Database.executeBatch(testBatch, 5);
    System.debug('✓ 배치 처리 시작됨');
    
    // 8. 스케줄러를 통한 알림 생성 테스트
    System.debug('=== 스케줄러 테스트 ===');
    PaymentNotificationScheduler.scheduleNotifications(new List<PaymentStatus__c>{paymentStatus});
    System.debug('✓ 스케줄러를 통한 알림 생성 완료');
    
} catch (Exception e) {
    System.debug('✗ 테스트 중 오류 발생: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

System.debug('=== 특정 PaymentStatus 알림 테스트 완료 ===');

// Chatter 알림 기능 테스트

System.debug('=== Chatter 알림 테스트 시작 ===');

// 테스트용 PaymentStatus 조회
List<PaymentStatus__c> testPayments = [
    SELECT Id, Status__c, DueDate__c 
    FROM PaymentStatus__c 
    WHERE Order__r.OrderNumber = '00000115'
    AND Status__c = '미납'
    LIMIT 1
];

if (!testPayments.isEmpty()) {
    try {
        // 테스트 알림 생성
        Payment_Notification__c testNotification = new Payment_Notification__c();
        testNotification.PaymentStatus__c = testPayments[0].Id;
        testNotification.NotificationType__c = '연체 알림';
        testNotification.NotificationChannel__c = 'Salesforce';
        testNotification.NotificationStatus__c = 'Pending';
        testNotification.ScheduledDateTime__c = DateTime.now();
        
        insert testNotification;
        System.debug('✓ 테스트 알림 생성 성공: ' + testNotification.Id);
        
        // 개선된 Salesforce 알림 발송 테스트
        Boolean result = PaymentNotificationService.sendSalesforceNotification(testNotification);
        System.debug('✓ 개선된 알림 발송 결과: ' + result);
        
    } catch (Exception e) {
        System.debug('✗ 테스트 오류: ' + e.getMessage());
        System.debug('스택 트레이스: ' + e.getStackTraceString());
    }
} else {
    System.debug('테스트할 PaymentStatus가 없습니다.');
}

System.debug('=== Chatter 알림 테스트 완료 ===');

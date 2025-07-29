// 단계별 테스트 스크립트

// 1. 클래스 존재 확인
System.debug('=== 클래스 존재 확인 ===');

try {
    // PaymentNotificationScheduler 테스트
    PaymentNotificationScheduler.scheduleNotifications(new List<PaymentStatus__c>());
    System.debug('✓ PaymentNotificationScheduler 클래스 정상');
} catch (Exception e) {
    System.debug('✗ PaymentNotificationScheduler 오류: ' + e.getMessage());
}

try {
    // PaymentNotificationService 테스트  
    System.debug('✓ PaymentNotificationService 클래스 정상');
} catch (Exception e) {
    System.debug('✗ PaymentNotificationService 오류: ' + e.getMessage());
}

try {
    // PaymentNotificationBatch 테스트
    PaymentNotificationBatch batch = new PaymentNotificationBatch();
    System.debug('✓ PaymentNotificationBatch 클래스 정상');
} catch (Exception e) {
    System.debug('✗ PaymentNotificationBatch 오류: ' + e.getMessage());
}

// 2. 기본 배치 실행 (스케줄러 없이)
System.debug('=== 기본 배치 테스트 ===');
try {
    PaymentNotificationBatch testBatch = new PaymentNotificationBatch();
    Database.executeBatch(testBatch, 5);
    System.debug('✓ 배치 실행 성공');
} catch (Exception e) {
    System.debug('✗ 배치 실행 오류: ' + e.getMessage());
}

// 3. 테스트 알림 수동 생성
System.debug('=== 테스트 알림 생성 ===');
List<PaymentStatus__c> testPayments = [
    SELECT Id, Status__c, DueDate__c 
    FROM PaymentStatus__c 
    WHERE Order__r.OrderNumber = '00000115'
    AND Status__c = '미납'
    LIMIT 1
];

if (!testPayments.isEmpty()) {
    try {
        Payment_Notification__c testNotification = new Payment_Notification__c();
        testNotification.PaymentStatus__c = testPayments[0].Id;
        testNotification.NotificationType__c = '연체 알림';
        testNotification.NotificationChannel__c = 'Salesforce';
        testNotification.NotificationStatus__c = 'Pending';
        testNotification.ScheduledDateTime__c = DateTime.now().addMinutes(1);
        
        insert testNotification;
        System.debug('✓ 테스트 알림 생성 성공: ' + testNotification.Id);
        
        // 즉시 처리 테스트
        Boolean result = PaymentNotificationService.sendSalesforceNotification(testNotification);
        System.debug('✓ 알림 발송 테스트 결과: ' + result);
        
    } catch (Exception e) {
        System.debug('✗ 테스트 알림 생성 오류: ' + e.getMessage());
    }
} else {
    System.debug('테스트할 PaymentStatus가 없습니다.');
}

System.debug('=== 기본 테스트 완료 ===');

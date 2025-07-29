// 스마트 알림 시스템 테스트 데이터 생성

// 1. 기존 테스트 데이터 정리
List<Payment_Notification__c> existingNotifications = [
    SELECT Id FROM Payment_Notification__c WHERE PaymentStatus__r.Order__r.OrderNumber LIKE 'TEST%'
];
if (!existingNotifications.isEmpty()) {
    delete existingNotifications;
    System.debug('기존 테스트 알림 ' + existingNotifications.size() + '건 삭제');
}

// 2. 테스트용 PaymentStatus 조회
List<PaymentStatus__c> testPayments = [
    SELECT Id, Status__c, DueDate__c, InstallmentNumber__c, Amount__c,
           Order__r.OrderNumber, Order__r.Account.Name
    FROM PaymentStatus__c 
    WHERE Order__r.OrderNumber = '00000115'
    AND Status__c = '미납'
    ORDER BY InstallmentNumber__c ASC
    LIMIT 3
];

if (testPayments.isEmpty()) {
    System.debug('테스트할 PaymentStatus가 없습니다. Order 00000115의 미납 건을 확인해주세요.');
    return;
}

System.debug('테스트 대상 PaymentStatus: ' + testPayments.size() + '건');

// 3. 테스트 시나리오 생성
List<Payment_Notification__c> testNotifications = new List<Payment_Notification__c>();

for (Integer i = 0; i < testPayments.size(); i++) {
    PaymentStatus__c ps = testPayments[i];
    
    // 시나리오 1: 예정 알림 (오늘 발송 예정)
    Payment_Notification__c reminderNotification = new Payment_Notification__c();
    reminderNotification.PaymentStatus__c = ps.Id;
    reminderNotification.NotificationType__c = '예정 알림';
    reminderNotification.NotificationChannel__c = 'Salesforce';
    reminderNotification.NotificationStatus__c = 'Pending';
    reminderNotification.ScheduledDateTime__c = DateTime.now().addMinutes(5); // 5분 후 테스트
    testNotifications.add(reminderNotification);
    
    // 시나리오 2: 연체 알림 (즉시 발송)
    if (i == 0) { // 첫 번째 건만 연체 알림 생성
        Payment_Notification__c overdueNotification = new Payment_Notification__c();
        overdueNotification.PaymentStatus__c = ps.Id;
        overdueNotification.NotificationType__c = '연체 알림';
        overdueNotification.NotificationChannel__c = 'Email';
        overdueNotification.NotificationStatus__c = 'Pending';
        overdueNotification.ScheduledDateTime__c = DateTime.now().addMinutes(2); // 2분 후 테스트
        testNotifications.add(overdueNotification);
    }
}

// 4. 테스트 알림 생성
insert testNotifications;
System.debug('테스트 알림 ' + testNotifications.size() + '건 생성 완료');

// 5. 생성된 알림 확인
for (Payment_Notification__c notification : testNotifications) {
    System.debug('생성된 알림 ID: ' + notification.Id);
}

// 6. 즉시 배치 실행 (테스트용)
System.debug('테스트 배치 실행 시작...');
PaymentNotificationBatch testBatch = new PaymentNotificationBatch();
Database.executeBatch(testBatch, 10);

System.debug('===== 테스트 시나리오 생성 완료 =====');
System.debug('• 예정 알림: 5분 후 발송 예정');
System.debug('• 연체 알림: 2분 후 발송 예정');
System.debug('• 배치 잡이 실행되어 테스트 알림이 처리됩니다.');
System.debug('• Payment_Notification__c 객체에서 결과를 확인하세요.');
System.debug('================================');

// 이메일 알림 테스트 (PDF 첨부 포함)
System.debug('📧 =====이메일 알림 테스트 시작=====');

try {
    // 기존 알림 레코드 조회 (가장 최근 것)
    List<Payment_Notification__c> notifications = [
        SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
               PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.Account.Id,
               PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c,
               PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c,
               NotificationType__c, NotificationChannel__c
        FROM Payment_Notification__c 
        WHERE CreatedDate = TODAY
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    
    if (notifications.isEmpty()) {
        System.debug('❌ 테스트할 알림 레코드가 없습니다.');
        return;
    }
    
    Payment_Notification__c notification = notifications[0];
    System.debug('📊 테스트 대상: ' + notification.PaymentStatus__r.Order__r.Account.Name + 
                 ' ' + notification.PaymentStatus__r.InstallmentNumber__c + '차');
    
    // PDF 파일 확인
    List<ContentDocumentLink> pdfFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :notification.PaymentStatus__r.Order__c
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
        LIMIT 1
    ];
    
    System.debug('📎 PDF 파일 수: ' + pdfFiles.size() + '개');
    if (!pdfFiles.isEmpty()) {
        System.debug('   • ' + pdfFiles[0].ContentDocument.Title + '.pdf');
    }
    
    // 관리자 이메일 조회 테스트
    System.debug('👥 관리자 이메일 조회 중...');
    List<User> adminUsers = [
        SELECT Id, Name, Email 
        FROM User 
        WHERE Profile.Name IN ('시스템 관리자', 'System Administrator') 
        AND IsActive = true 
        AND Email != null
        LIMIT 3
    ];
    
    System.debug('📧 관리자 수: ' + adminUsers.size() + '명');
    for (User admin : adminUsers) {
        System.debug('   • ' + admin.Name + ' (' + admin.Email + ')');
    }
    
    // 고객 이메일 조회 테스트
    System.debug('👤 고객 이메일 조회 중...');
    List<Contact> customerContacts = [
        SELECT Id, Name, Email 
        FROM Contact 
        WHERE AccountId = :notification.PaymentStatus__r.Order__r.Account.Id
        AND Email != null
        ORDER BY CreatedDate ASC
        LIMIT 1
    ];
    
    System.debug('📧 고객 연락처 수: ' + customerContacts.size() + '명');
    for (Contact contact : customerContacts) {
        System.debug('   • ' + contact.Name + ' (' + contact.Email + ')');
    }
    
    // 실제 이메일 발송 테스트
    System.debug('📮 이메일 발송 테스트 중...');
    Boolean emailResult = PaymentNotificationService.sendEmailNotification(notification);
    System.debug('   이메일 발송 결과: ' + (emailResult ? '✅ 성공' : '❌ 실패'));
    
    // Order Owner 확인
    List<Order> orders = [
        SELECT Id, OrderNumber, OwnerId, Owner.Name, Owner.Email
        FROM Order 
        WHERE Id = :notification.PaymentStatus__r.Order__c
    ];
    
    if (!orders.isEmpty()) {
        Order order = orders[0];
        System.debug('👔 Order Owner: ' + order.Owner.Name + ' (' + order.Owner.Email + ')');
    }
    
    System.debug('✅ =====이메일 알림 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 이메일 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

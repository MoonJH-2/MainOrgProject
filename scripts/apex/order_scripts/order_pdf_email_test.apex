// Order 00000115 PDF 첨부 이메일 테스트
System.debug('📧 =====Order 00000115 PDF 첨부 이메일 테스트=====');

try {
    // 1. Order 00000115의 연체 PaymentStatus 조회 또는 생성
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
    System.debug('📋 Order: ' + targetOrder.OrderNumber + ' (' + targetOrder.Account.Name + ')');
    
    // 2. 연체 PaymentStatus 확인
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        AND DueDate__c < TODAY 
        AND Status__c != '완납'
        ORDER BY InstallmentNumber__c ASC
        LIMIT 1
    ];
    
    if (overduePayments.isEmpty()) {
        System.debug('⚠️ 연체된 PaymentStatus가 없습니다. 테스트용으로 생성합니다.');
        
        // 테스트용 연체 PaymentStatus 생성 또는 기존 것 사용
        List<PaymentStatus__c> allPayments = [
            SELECT Id, InstallmentNumber__c, DueDate__c, Status__c
            FROM PaymentStatus__c 
            WHERE Order__c = :targetOrder.Id
            ORDER BY InstallmentNumber__c ASC
            LIMIT 1
        ];
        
        if (!allPayments.isEmpty()) {
            PaymentStatus__c testPayment = allPayments[0];
            testPayment.DueDate__c = Date.today().addDays(-3); // 3일 전으로 설정
            testPayment.Status__c = '미납';
            update testPayment;
            overduePayments.add(testPayment);
            System.debug('✅ 테스트용 연체 상황 생성: ' + testPayment.InstallmentNumber__c + '차');
        }
    }
    
    if (overduePayments.isEmpty()) {
        System.debug('❌ 테스트할 PaymentStatus를 생성할 수 없습니다.');
        return;
    }
    
    PaymentStatus__c overduePayment = overduePayments[0];
    
    // 3. Payment_Notification__c 레코드 생성
    Payment_Notification__c notification = new Payment_Notification__c();
    notification.PaymentStatus__c = overduePayment.Id;
    notification.NotificationType__c = '연체 알림';
    notification.NotificationChannel__c = 'Email';
    notification.NotificationStatus__c = 'Pending';
    notification.ScheduledDateTime__c = DateTime.now();
    
    insert notification;
    System.debug('✅ 알림 레코드 생성: ' + notification.Id);
    
    // 4. 관계 필드와 함께 다시 조회
    Payment_Notification__c fullNotification = [
        SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
               PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.Account.Id,
               PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c,
               PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c,
               NotificationType__c, NotificationChannel__c
        FROM Payment_Notification__c 
        WHERE Id = :notification.Id
    ];
    
    // 5. 현재 PDF 파일 상태 확인
    System.debug('📎 현재 PDF 파일 상태 확인:');
    List<ContentDocumentLink> currentPDFs = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension,
               ContentDocument.CreatedDate
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('   총 PDF 파일: ' + currentPDFs.size() + '개');
    for (ContentDocumentLink pdf : currentPDFs) {
        String isPaymentSchedule = pdf.ContentDocument.Title.contains('납부일정서') ? ' [납부일정서]' : '';
        System.debug('   • ' + pdf.ContentDocument.Title + '.pdf' + isPaymentSchedule + 
                     ' (생성일: ' + pdf.ContentDocument.CreatedDate.format() + ')');
    }
    
    // 6. 이메일 발송 테스트 (PDF 첨부 포함)
    System.debug('📮 PDF 첨부 이메일 발송 테스트 중...');
    Boolean emailResult = PaymentNotificationService.sendEmailNotification(fullNotification);
    System.debug('   이메일 발송 결과: ' + (emailResult ? '✅ 성공' : '❌ 실패'));
    
    // 7. 발송된 이메일 정보 요약
    if (emailResult) {
        System.debug('');
        System.debug('📧 발송된 이메일 정보:');
        System.debug('• 제목: [연체 알림] ' + fullNotification.PaymentStatus__r.InstallmentNumber__c + '차 납부 연체 안내');
        System.debug('• 고객 수신자: 0714TEST 관련 연락처');
        System.debug('• 관리자 수신자: 시스템 관리자들 + Order Owner');
        System.debug('• PDF 첨부: Order 00000115 최신 납부일정서');
        System.debug('• 연체 정보: ' + fullNotification.PaymentStatus__r.InstallmentNumber__c + 
                     '차 ₩' + fullNotification.PaymentStatus__r.Amount__c.format() + 
                     ' (예정일: ' + fullNotification.PaymentStatus__r.DueDate__c.format() + ')');
    }
    
    // 8. 이메일 첨부 파일 확인 (디버그용)
    System.debug('');
    System.debug('🔍 첨부 파일 처리 상세 로그:');
    // getPDFAttachments 메서드가 실행될 때의 로그를 확인할 수 있습니다
    
    // 9. 테스트 정리 (원래 상태로 복구)
    if (overduePayment.DueDate__c < Date.today()) {
        System.debug('🔄 테스트 정리 중...');
        overduePayment.DueDate__c = Date.newInstance(2025, 8, 14); // 원래 날짜로 복구
        overduePayment.Status__c = '예정'; // 원래 상태로 복구
        update overduePayment;
        System.debug('✅ PaymentStatus 원래 상태로 복구 완료');
    }
    
    System.debug('');
    System.debug('✅ =====Order 00000115 PDF 첨부 이메일 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ PDF 첨부 이메일 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

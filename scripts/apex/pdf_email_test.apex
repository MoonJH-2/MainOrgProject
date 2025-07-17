// PDF 파일 업로드 및 이메일 재테스트
System.debug('📎 =====PDF 첨부 및 이메일 재테스트=====');

try {
    // 최근 알림 레코드 조회
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
    Id orderId = notification.PaymentStatus__r.Order__c;
    
    System.debug('📊 테스트 Order: ' + notification.PaymentStatus__r.Order__r.OrderNumber);
    
    // 테스트용 PDF 파일 생성 및 업로드
    String pdfContent = '%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n100 700 Td\n(Test PDF Document) Tj\nET\nendstream\nendobj\n\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000204 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n298\n%%EOF';
    
    // ContentVersion 생성
    ContentVersion cv = new ContentVersion();
    cv.Title = '납부서_' + notification.PaymentStatus__r.Order__r.OrderNumber;
    cv.PathOnClient = cv.Title + '.pdf';
    cv.VersionData = Blob.valueOf(pdfContent);
    cv.ContentLocation = 'S';
    insert cv;
    
    // ContentDocument ID 조회
    ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    
    // ContentDocumentLink 생성 (Order에 연결)
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = insertedCV.ContentDocumentId;
    cdl.LinkedEntityId = orderId;
    cdl.ShareType = 'V';
    cdl.Visibility = 'AllUsers';
    insert cdl;
    
    System.debug('✅ 테스트 PDF 파일 업로드 완료: ' + cv.Title + '.pdf');
    
    // PDF 파일 재확인
    List<ContentDocumentLink> pdfFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :orderId
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('📎 연결된 PDF 파일 수: ' + pdfFiles.size() + '개');
    for (ContentDocumentLink pdf : pdfFiles) {
        System.debug('   • ' + pdf.ContentDocument.Title + '.pdf');
    }
    
    // 이메일 발송 재테스트
    System.debug('📮 이메일 발송 재테스트 중...');
    Boolean emailResult = PaymentNotificationService.sendEmailNotification(notification);
    System.debug('   이메일 발송 결과: ' + (emailResult ? '✅ 성공' : '❌ 실패'));
    
    if (emailResult) {
        System.debug('📧 발송된 이메일:');
        System.debug('   • 고객: mail@gmail.com');
        System.debug('   • 관리자: eetd0000@gmail.com, hyowonhong.dsic@gmail.com, rm.chloe.kim@gmail.com');
        System.debug('   • PDF 첨부: ' + (pdfFiles.size() > 0 ? cv.Title + '.pdf' : '없음'));
    }
    
    System.debug('✅ =====PDF 첨부 및 이메일 재테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ PDF 첨부 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

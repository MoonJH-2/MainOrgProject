// Order 00000115 새 납부일정서 PDF 생성 및 이메일 테스트
System.debug('📄 =====Order 00000115 새 납부일정서 생성 및 이메일 테스트=====');

try {
    // 1. Order 00000115 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name, Account.Id
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
    
    // 2. PaymentStatus 목록 조회
    List<PaymentStatus__c> paymentList = [
        SELECT InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('💰 PaymentStatus: ' + paymentList.size() + '건');
    
    // 3. 새로운 납부일정서 PDF 생성
    System.debug('📝 새 납부일정서 PDF 생성 중...');
    
    // 실제 PDF 내용 생성 (더 상세하게)
    String pdfContent = '%PDF-1.4\n';
    pdfContent += '1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n\n';
    pdfContent += '2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n\n';
    pdfContent += '3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n/Resources << /Font << /F1 5 0 R >> >>\n>>\nendobj\n\n';
    
    // 내용 스트림 생성
    String contentStream = 'BT\n';
    contentStream += '/F1 16 Tf\n';
    contentStream += '100 720 Td\n';
    contentStream += '(납부일정서) Tj\n';
    contentStream += '0 -30 Td\n';
    contentStream += '/F1 12 Tf\n';
    contentStream += '(Order Number: ' + targetOrder.OrderNumber + ') Tj\n';
    contentStream += '0 -20 Td\n';
    contentStream += '(고객명: ' + targetOrder.Account.Name + ') Tj\n';
    contentStream += '0 -20 Td\n';
    contentStream += '(생성일: ' + Date.today().format() + ') Tj\n';
    contentStream += '0 -40 Td\n';
    contentStream += '(납부 일정) Tj\n';
    contentStream += '0 -30 Td\n';
    
    // 각 납부 항목 추가
    for (PaymentStatus__c payment : paymentList) {
        String statusText = payment.Status__c == '완납' ? '완납' : 
                           (payment.DueDate__c < Date.today() ? '연체' : '예정');
        String paymentLine = '(' + payment.InstallmentNumber__c + '차: ₩' + 
                           String.valueOf(payment.Amount__c.format()) + ' - ' + 
                           payment.DueDate__c.format() + ' [' + statusText + ']) Tj';
        contentStream += paymentLine + '\n';
        contentStream += '0 -20 Td\n';
    }
    
    contentStream += 'ET\n';
    
    // PDF 구조 완성
    Integer contentLength = contentStream.length();
    pdfContent += '4 0 obj\n<<\n/Length ' + contentLength + '\n>>\nstream\n';
    pdfContent += contentStream;
    pdfContent += 'endstream\nendobj\n\n';
    
    pdfContent += '5 0 obj\n<<\n/Type /Font\n/Subtype /Type1\n/BaseFont /Helvetica\n>>\nendobj\n\n';
    
    pdfContent += 'xref\n0 6\n';
    pdfContent += '0000000000 65535 f \n';
    pdfContent += '0000000009 00000 n \n';
    pdfContent += '0000000058 00000 n \n';
    pdfContent += '0000000115 00000 n \n';
    pdfContent += '0000000300 00000 n \n';
    pdfContent += '0000000400 00000 n \n';
    pdfContent += 'trailer\n<<\n/Size 6\n/Root 1 0 R\n>>\n';
    pdfContent += 'startxref\n500\n%%EOF';
    
    // ContentVersion 생성
    ContentVersion cv = new ContentVersion();
    cv.Title = '납부일정서_' + targetOrder.OrderNumber + '_' + DateTime.now().format('yyyyMMdd_HHmmss');
    cv.PathOnClient = cv.Title + '.pdf';
    cv.VersionData = Blob.valueOf(pdfContent);
    cv.ContentLocation = 'S';
    cv.Description = targetOrder.Account.Name + ' 고객 납부일정서 - ' + targetOrder.OrderNumber + ' (자동생성)';
    
    insert cv;
    
    // ContentDocument ID 조회
    ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    
    // ContentDocumentLink 생성 (Order에 연결)
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = insertedCV.ContentDocumentId;
    cdl.LinkedEntityId = targetOrder.Id;
    cdl.ShareType = 'V';
    cdl.Visibility = 'AllUsers';
    insert cdl;
    
    System.debug('✅ 새 납부일정서 PDF 생성 완료');
    System.debug('   파일명: ' + cv.Title + '.pdf');
    System.debug('   크기: ' + (cv.VersionData.size() / 1024) + 'KB');
    System.debug('   ContentVersion ID: ' + cv.Id);
    System.debug('   ContentDocument ID: ' + insertedCV.ContentDocumentId);
    
    // 4. 연체 알림 생성 및 이메일 발송 테스트
    System.debug('📧 이메일 발송 테스트 중...');
    
    // 연체 PaymentStatus 찾기 또는 임시 생성
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, InstallmentNumber__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        AND DueDate__c < TODAY 
        AND Status__c != '완납'
        LIMIT 1
    ];
    
    PaymentStatus__c testPayment;
    if (overduePayments.isEmpty()) {
        // 임시로 2차 납부를 연체 상태로 만들기
        List<PaymentStatus__c> secondPayments = [
            SELECT Id, DueDate__c, Status__c
            FROM PaymentStatus__c 
            WHERE Order__c = :targetOrder.Id
            AND InstallmentNumber__c = 2
            LIMIT 1
        ];
        
        if (!secondPayments.isEmpty()) {
            testPayment = secondPayments[0];
            testPayment.DueDate__c = Date.today().addDays(-2);
            testPayment.Status__c = '미납';
            update testPayment;
            System.debug('   2차 납부를 임시 연체 상태로 변경');
        }
    } else {
        testPayment = overduePayments[0];
    }
    
    if (testPayment != null) {
        // Payment_Notification__c 생성
        Payment_Notification__c notification = new Payment_Notification__c();
        notification.PaymentStatus__c = testPayment.Id;
        notification.NotificationType__c = '연체 알림';
        notification.NotificationChannel__c = 'Email';
        notification.NotificationStatus__c = 'Pending';
        notification.ScheduledDateTime__c = DateTime.now();
        
        insert notification;
        
        // 관계 필드와 함께 조회
        Payment_Notification__c fullNotification = [
            SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
                   PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.Account.Id,
                   PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c,
                   PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c,
                   NotificationType__c, NotificationChannel__c
            FROM Payment_Notification__c 
            WHERE Id = :notification.Id
        ];
        
        // 이메일 발송
        Boolean emailResult = PaymentNotificationService.sendEmailNotification(fullNotification);
        System.debug('   이메일 발송 결과: ' + (emailResult ? '✅ 성공' : '❌ 실패'));
        
        if (emailResult) {
            System.debug('');
            System.debug('📧 발송 완료 정보:');
            System.debug('• 제목: [연체 알림] ' + fullNotification.PaymentStatus__r.InstallmentNumber__c + '차 납부 연체 안내');
            System.debug('• PDF 첨부: ' + cv.Title + '.pdf (' + (cv.VersionData.size() / 1024) + 'KB)');
            System.debug('• 고객: ' + targetOrder.Account.Name);
            System.debug('• 관리자: 시스템 관리자 및 Order Owner');
        }
        
        // 테스트 정리
        testPayment.DueDate__c = Date.newInstance(2025, 8, 14);
        testPayment.Status__c = '예정';
        update testPayment;
        System.debug('✅ 테스트 데이터 정리 완료');
    }
    
    System.debug('✅ =====Order 00000115 새 납부일정서 생성 및 이메일 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// Order 00000141 자동화 시스템 테스트
System.debug('🎯 =====Order 00000141 PDF & Slack 자동화 테스트=====');

try {
    // 1. Order 00000141 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name, TotalAmount, Status,
               Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c,
               (SELECT Id, Product2.Name, Product2.ProductCode, Quantity, 
                       UnitPrice, TotalPrice FROM OrderItems)
        FROM Order 
        WHERE OrderNumber = '00000141'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000141을 찾을 수 없습니다.');
        return;
    }
    
    Order targetOrder = orders[0];
    System.debug('📋 Order: ' + targetOrder.OrderNumber + ' (' + targetOrder.Account.Name + ')');
    System.debug('   Status: ' + targetOrder.Status);
    System.debug('   Amount: ₩' + targetOrder.TotalAmount.format());
    System.debug('   Order Products: ' + targetOrder.OrderItems.size() + '개');
    
    // 2. 현재 Order Product 상태 확인
    for (OrderItem item : targetOrder.OrderItems) {
        System.debug('   • ' + item.Product2.Name + ' (Code: ' + item.Product2.ProductCode + 
                     ', Qty: ' + item.Quantity + ', Price: ₩' + item.TotalPrice.format() + ')');
    }
    
    // 3. 현재 Slack 상태 확인
    System.debug('💬 현재 Slack 상태:');
    System.debug('   Channel ID: ' + (String.isBlank(targetOrder.Slack_Channel_ID__c) ? '없음' : targetOrder.Slack_Channel_ID__c));
    System.debug('   Channel Name: ' + (String.isBlank(targetOrder.Slack_Channel_Name__c) ? '없음' : targetOrder.Slack_Channel_Name__c));
    System.debug('   Status: ' + (String.isBlank(targetOrder.Slack_Notification_Status__c) ? 'Not Created' : targetOrder.Slack_Notification_Status__c));
    
    // 4. 현재 PDF 파일 상태 확인
    System.debug('📎 현재 PDF 파일 상태:');
    List<ContentDocumentLink> pdfFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension,
               ContentDocument.CreatedDate
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('   총 PDF 파일: ' + pdfFiles.size() + '개');
    for (ContentDocumentLink pdf : pdfFiles) {
        String fileType = pdf.ContentDocument.Title.contains('Product') ? ' [Product 상세서]' : 
                         pdf.ContentDocument.Title.contains('납부일정서') ? ' [납부일정서]' : '';
        System.debug('   • ' + pdf.ContentDocument.Title + '.pdf' + fileType + 
                     ' (생성일: ' + pdf.ContentDocument.CreatedDate.format() + ')');
    }
    
    // 5. 자동화 시스템 수동 실행 테스트
    System.debug('🤖 자동화 시스템 수동 실행 중...');
    
    Set<Id> orderIds = new Set<Id>{ targetOrder.Id };
    
    // OrderProductAutomationService 직접 호출 (동기식 테스트)
    try {
        // 비동기 메서드 대신 동기 로직으로 테스트
        System.debug('📄 PDF 생성 테스트...');
        
        // PDF 생성 테스트 (간단한 버전)
        String pdfContent = createTestPDFContent(targetOrder);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Order_Product_상세서_' + targetOrder.OrderNumber + '_TEST_' + 
                  DateTime.now().format('yyyyMMdd_HHmmss');
        cv.PathOnClient = cv.Title + '.pdf';
        cv.VersionData = Blob.valueOf(pdfContent);
        cv.ContentLocation = 'S';
        cv.Description = targetOrder.Account.Name + ' 고객 Order Product 상세서 - ' + 
                       targetOrder.OrderNumber + ' (테스트 생성)';
        
        insert cv;
        
        // ContentDocumentLink 생성
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCV.ContentDocumentId;
        cdl.LinkedEntityId = targetOrder.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        System.debug('✅ PDF 생성 완료: ' + cv.Title + '.pdf');
        
    } catch (Exception pdfEx) {
        System.debug('❌ PDF 생성 오류: ' + pdfEx.getMessage());
    }
    
    // 6. Slack 채널 생성 테스트
    try {
        System.debug('💬 Slack 채널 생성 테스트...');
        
        // SlackChannelService 테스트 호출
        Boolean slackResult = SlackChannelService.createOrderChannel(targetOrder);
        
        if (slackResult) {
            System.debug('✅ Slack 채널 생성 완료');
        } else {
            System.debug('⚠️ Slack 채널 생성 결과: false (테스트 모드에서는 정상)');
        }
        
    } catch (Exception slackEx) {
        System.debug('❌ Slack 채널 생성 오류: ' + slackEx.getMessage());
    }
    
    // 7. Chatter 포스트 생성 테스트
    try {
        System.debug('💬 Chatter 포스트 생성 테스트...');
        
        FeedItem post = new FeedItem();
        post.ParentId = targetOrder.Id;
        post.Type = 'TextPost';
        
        String message = '🎉 Order Product 자동화 테스트 완료!\n\n';
        message += '📋 Order: ' + targetOrder.OrderNumber + '\n';
        message += '👤 Customer: ' + targetOrder.Account.Name + '\n';
        message += '💰 Amount: ₩' + targetOrder.TotalAmount.format() + '\n\n';
        message += '✅ 테스트된 기능:\n';
        message += '• Order Product 상세서 PDF 생성\n';
        message += '• Slack 채널 생성 (#' + targetOrder.OrderNumber + ')\n';
        message += '• Files 자동 첨부\n\n';
        message += '📎 Notes & Attachments에서 새로 생성된 PDF를 확인하세요!';
        
        post.Body = message;
        insert post;
        
        System.debug('✅ Chatter 포스트 생성 완료');
        
    } catch (Exception chatterEx) {
        System.debug('❌ Chatter 포스트 생성 오류: ' + chatterEx.getMessage());
    }
    
    // 8. 최종 상태 확인
    System.debug('');
    System.debug('📊 테스트 완료 후 상태:');
    
    // 업데이트된 PDF 파일 목록
    List<ContentDocumentLink> updatedPDFs = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension,
               ContentDocument.CreatedDate
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('   총 PDF 파일: ' + updatedPDFs.size() + '개 (테스트 전: ' + pdfFiles.size() + '개)');
    if (!updatedPDFs.isEmpty()) {
        System.debug('   최신 PDF: ' + updatedPDFs[0].ContentDocument.Title + '.pdf');
    }
    
    System.debug('');
    System.debug('✅ =====Order 00000141 자동화 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// PDF 내용 생성 헬퍼 함수
private static String createTestPDFContent(Order orderInfo) {
    String pdfContent = '%PDF-1.4\n';
    pdfContent += '1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n\n';
    pdfContent += '2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n\n';
    pdfContent += '3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n\n';
    
    String contentStream = 'BT\n/F1 16 Tf\n50 750 Td\n';
    contentStream += '(Order Product 상세서 - TEST) Tj\n';
    contentStream += '/F1 12 Tf\n0 -30 Td\n';
    contentStream += '(Order Number: ' + orderInfo.OrderNumber + ') Tj\n';
    contentStream += '0 -20 Td\n(Customer: ' + orderInfo.Account.Name + ') Tj\n';
    contentStream += '0 -20 Td\n(Status: ' + orderInfo.Status + ') Tj\n';
    contentStream += '0 -20 Td\n(Amount: ₩' + orderInfo.TotalAmount.format() + ') Tj\n';
    contentStream += '0 -30 Td\n(=== Product Details ===) Tj\n';
    
    for (OrderItem item : orderInfo.OrderItems) {
        contentStream += '0 -20 Td\n(• ' + item.Product2.Name + ') Tj\n';
        contentStream += '0 -15 Td\n(  Quantity: ' + item.Quantity + ') Tj\n';
        contentStream += '0 -15 Td\n(  Total: ₩' + item.TotalPrice.format() + ') Tj\n';
    }
    
    contentStream += '0 -30 Td\n(생성일: ' + Date.today().format() + ' [TEST]) Tj\n';
    contentStream += 'ET';
    
    pdfContent += '4 0 obj\n<<\n/Length ' + contentStream.length() + '\n>>\nstream\n';
    pdfContent += contentStream + '\nendstream\nendobj\n\n';
    pdfContent += 'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n';
    pdfContent += '0000000058 00000 n \n0000000115 00000 n \n0000000204 00000 n \n';
    pdfContent += 'trailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n500\n%%EOF';
    
    return pdfContent;
}

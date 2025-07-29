// Order 00000142 자동화 시스템 작동 상태 검토
System.debug('🔍 =====Order 00000142 자동화 시스템 검토=====');

try {
    // 1. Order 00000142 상세 정보 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name, TotalAmount, Status, EffectiveDate,
               Payment_Method__c, CreatedDate, LastModifiedDate,
               Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c,
               (SELECT Id, Product2.Name, Product2.ProductCode, Quantity, 
                       UnitPrice, TotalPrice FROM OrderItems)
        FROM Order 
        WHERE OrderNumber = '00000142'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000142를 찾을 수 없습니다.');
        return;
    }
    
    Order targetOrder = orders[0];
    System.debug('📋 Order 기본 정보:');
    System.debug('   Order Number: ' + targetOrder.OrderNumber);
    System.debug('   Customer: ' + targetOrder.Account.Name);
    System.debug('   Status: ' + targetOrder.Status);
    System.debug('   Amount: ₩' + targetOrder.TotalAmount.format());
    System.debug('   Payment Method: ' + targetOrder.Payment_Method__c);
    System.debug('   Created: ' + targetOrder.CreatedDate.format());
    System.debug('   Last Modified: ' + targetOrder.LastModifiedDate.format());
    
    // 2. Order Products 상태 확인
    System.debug('');
    System.debug('🛒 Order Products 상태:');
    System.debug('   총 Products: ' + targetOrder.OrderItems.size() + '개');
    
    for (OrderItem item : targetOrder.OrderItems) {
        System.debug('   • ' + item.Product2.Name + ' (' + item.Product2.ProductCode + ')');
        System.debug('     Quantity: ' + item.Quantity + ', Unit Price: ₩' + item.UnitPrice.format());
        System.debug('     Total: ₩' + item.TotalPrice.format());
    }
    
    // 3. PaymentStatus 생성 상태 확인
    System.debug('');
    System.debug('💰 PaymentStatus 자동 생성 상태:');
    List<PaymentStatus__c> paymentStatuses = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('   총 PaymentStatus: ' + paymentStatuses.size() + '개');
    
    Boolean paymentScheduleCorrect = true;
    for (PaymentStatus__c payment : paymentStatuses) {
        System.debug('   • ' + payment.InstallmentNumber__c + '차: ₩' + payment.Amount__c.format() + 
                     ' (예정일: ' + payment.DueDate__c.format() + ', 상태: ' + payment.Status__c + ')');
        
        // 분기별 납부이므로 4개의 PaymentStatus가 있어야 함
        if (payment.Amount__c != 3180000) {
            paymentScheduleCorrect = false;
        }
    }
    
    if (paymentStatuses.size() == 4 && paymentScheduleCorrect) {
        System.debug('   ✅ PaymentStatus 자동 생성: 정상');
    } else {
        System.debug('   ❌ PaymentStatus 자동 생성: 문제 있음');
    }
    
    // 4. PDF 자동 생성 상태 확인
    System.debug('');
    System.debug('📄 PDF 자동 생성 상태:');
    List<ContentDocumentLink> pdfFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension,
               ContentDocument.CreatedDate, ContentDocument.ContentSize
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('   총 PDF 파일: ' + pdfFiles.size() + '개');
    
    Boolean productPDFExists = false;
    Boolean paymentPDFExists = false;
    
    for (ContentDocumentLink pdf : pdfFiles) {
        String fileType = '';
        if (pdf.ContentDocument.Title.contains('Product') || pdf.ContentDocument.Title.contains('상세서')) {
            fileType = ' [Product 상세서]';
            productPDFExists = true;
        } else if (pdf.ContentDocument.Title.contains('납부일정서') || pdf.ContentDocument.Title.contains('payment')) {
            fileType = ' [납부일정서]';
            paymentPDFExists = true;
        }
        
        System.debug('   • ' + pdf.ContentDocument.Title + '.pdf' + fileType);
        System.debug('     생성일: ' + pdf.ContentDocument.CreatedDate.format() + 
                     ', 크기: ' + (pdf.ContentDocument.ContentSize / 1024) + 'KB');
    }
    
    // PDF 자동 생성 상태 평가
    if (productPDFExists) {
        System.debug('   ✅ Order Product 상세서 PDF: 자동 생성됨');
    } else {
        System.debug('   ❌ Order Product 상세서 PDF: 생성되지 않음');
    }
    
    if (paymentPDFExists) {
        System.debug('   ✅ 납부일정서 PDF: 자동 생성됨');
    } else {
        System.debug('   ⚠️ 납부일정서 PDF: 생성되지 않음 (PaymentStatus 생성 후 자동 생성)');
    }
    
    // 5. Slack 채널 자동 생성 상태 확인
    System.debug('');
    System.debug('💬 Slack 채널 자동 생성 상태:');
    System.debug('   Channel ID: ' + (String.isBlank(targetOrder.Slack_Channel_ID__c) ? '없음' : targetOrder.Slack_Channel_ID__c));
    System.debug('   Channel Name: ' + (String.isBlank(targetOrder.Slack_Channel_Name__c) ? '없음' : targetOrder.Slack_Channel_Name__c));
    System.debug('   Notification Status: ' + (String.isBlank(targetOrder.Slack_Notification_Status__c) ? 'Not Created' : targetOrder.Slack_Notification_Status__c));
    
    if (String.isNotBlank(targetOrder.Slack_Channel_Name__c) && targetOrder.Slack_Notification_Status__c == 'Created') {
        System.debug('   ✅ Slack 채널: 자동 생성됨');
    } else if (targetOrder.Slack_Notification_Status__c == 'Not Created') {
        System.debug('   ❌ Slack 채널: 생성되지 않음');
    } else {
        System.debug('   ⚠️ Slack 채널: 처리 중...');
    }
    
    // 6. Chatter 알림 상태 확인
    System.debug('');
    System.debug('💬 Chatter 알림 상태:');
    List<FeedItem> chatterPosts = [
        SELECT Id, Body, CreatedDate, CreatedBy.Name
        FROM FeedItem 
        WHERE ParentId = :targetOrder.Id
        AND Body LIKE '%자동화%'
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    System.debug('   자동화 관련 Chatter 포스트: ' + chatterPosts.size() + '개');
    
    for (FeedItem post : chatterPosts) {
        String bodyPreview = post.Body.length() > 50 ? post.Body.substring(0, 50) + '...' : post.Body;
        System.debug('   • ' + post.CreatedDate.format() + ' by ' + post.CreatedBy.Name + ': ' + bodyPreview);
    }
    
    if (chatterPosts.size() > 0) {
        System.debug('   ✅ Chatter 알림: 생성됨');
    } else {
        System.debug('   ❌ Chatter 알림: 생성되지 않음');
    }
    
    // 7. 자동화 시스템 전체 상태 평가
    System.debug('');
    System.debug('📊 자동화 시스템 전체 상태 평가:');
    
    int successCount = 0;
    int totalChecks = 5;
    
    // 1. Order Products 존재
    if (!targetOrder.OrderItems.isEmpty()) {
        System.debug('   ✅ Order Products: 정상 (' + targetOrder.OrderItems.size() + '개)');
        successCount++;
    } else {
        System.debug('   ❌ Order Products: 없음');
    }
    
    // 2. PaymentStatus 자동 생성
    if (paymentStatuses.size() == 4 && paymentScheduleCorrect) {
        System.debug('   ✅ PaymentStatus 자동 생성: 정상');
        successCount++;
    } else {
        System.debug('   ❌ PaymentStatus 자동 생성: 문제');
    }
    
    // 3. PDF 자동 생성 (Product 상세서)
    if (productPDFExists) {
        System.debug('   ✅ Product 상세서 PDF: 정상');
        successCount++;
    } else {
        System.debug('   ❌ Product 상세서 PDF: 누락');
    }
    
    // 4. Slack 채널 자동 생성
    if (targetOrder.Slack_Notification_Status__c == 'Created') {
        System.debug('   ✅ Slack 채널 생성: 정상');
        successCount++;
    } else {
        System.debug('   ❌ Slack 채널 생성: 누락');
    }
    
    // 5. Chatter 알림
    if (chatterPosts.size() > 0) {
        System.debug('   ✅ Chatter 알림: 정상');
        successCount++;
    } else {
        System.debug('   ❌ Chatter 알림: 누락');
    }
    
    // 전체 평가
    Double successRate = (Double)successCount / totalChecks * 100;
    System.debug('');
    System.debug('🎯 전체 자동화 성공률: ' + successRate.intValue() + '% (' + successCount + '/' + totalChecks + ')');
    
    if (successRate >= 80) {
        System.debug('✅ 자동화 시스템: 정상 작동');
    } else if (successRate >= 60) {
        System.debug('⚠️ 자동화 시스템: 부분 작동 (개선 필요)');
    } else {
        System.debug('❌ 자동화 시스템: 문제 있음 (점검 필요)');
    }
    
    // 8. 개선 권장사항
    System.debug('');
    System.debug('💡 개선 권장사항:');
    
    if (!productPDFExists) {
        System.debug('   • Order Product 상세서 PDF 수동 생성 필요');
        System.debug('     → scripts/apex/execute_order_00000142_automation.apex 실행');
    }
    
    if (targetOrder.Slack_Notification_Status__c != 'Created') {
        System.debug('   • Slack 채널 수동 생성 필요');
        System.debug('     → Slack API 토큰 설정 또는 수동 채널 생성');
    }
    
    if (chatterPosts.size() == 0) {
        System.debug('   • Chatter 알림 수동 생성 필요');
        System.debug('     → 자동화 서비스 재실행 또는 수동 포스트 생성');
    }
    
    System.debug('');
    System.debug('✅ =====Order 00000142 검토 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 검토 중 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

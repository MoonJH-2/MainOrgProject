// Order 00000142 단계별 자동화 시스템 검토
System.debug('🔍 =====Order 00000142 단계별 자동화 검토=====');

try {
    // 1. 기본 Order 정보 확인
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
    
    System.debug('📋 STEP 1: 기본 Order 정보 검토');
    System.debug('   Order Number: ' + targetOrder.OrderNumber);
    System.debug('   Customer: ' + targetOrder.Account.Name);
    System.debug('   Status: ' + targetOrder.Status + ' ✅');
    System.debug('   Amount: ₩' + targetOrder.TotalAmount.format() + ' ✅');
    System.debug('   Payment Method: ' + targetOrder.Payment_Method__c + ' (분기별) ✅');
    System.debug('   Created: ' + targetOrder.CreatedDate.format());
    System.debug('   Last Modified: ' + targetOrder.LastModifiedDate.format());
    
    // 2. Order Products 검토
    System.debug('');
    System.debug('🛒 STEP 2: Order Products 검토');
    System.debug('   총 Products: ' + targetOrder.OrderItems.size() + '개');
    
    if (targetOrder.OrderItems.size() > 0) {
        System.debug('   ✅ Order Products 존재함');
        for (OrderItem item : targetOrder.OrderItems) {
            System.debug('   • ' + item.Product2.Name + ' (' + item.Product2.ProductCode + ')');
            System.debug('     Quantity: ' + item.Quantity + ', Unit Price: ₩' + item.UnitPrice.format());
            System.debug('     Total: ₩' + item.TotalPrice.format());
        }
    } else {
        System.debug('   ❌ Order Products 없음');
    }
    
    // 3. PaymentStatus 자동 생성 검토
    System.debug('');
    System.debug('💰 STEP 3: PaymentStatus 자동 생성 검토');
    List<PaymentStatus__c> paymentStatuses = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('   총 PaymentStatus: ' + paymentStatuses.size() + '개');
    
    Boolean paymentScheduleCorrect = true;
    Decimal expectedAmount = targetOrder.TotalAmount / 4; // 분기별이므로 4분할
    
    for (PaymentStatus__c payment : paymentStatuses) {
        String statusIcon = payment.Status__c == '미납' ? '⏳' : '✅';
        System.debug('   ' + statusIcon + ' ' + payment.InstallmentNumber__c + '차: ₩' + payment.Amount__c.format() + 
                     ' (예정일: ' + payment.DueDate__c.format() + ', 상태: ' + payment.Status__c + ')');
        
        // 금액 검증
        if (Math.abs(payment.Amount__c - expectedAmount) > 1) {
            paymentScheduleCorrect = false;
        }
    }
    
    if (paymentStatuses.size() == 4 && paymentScheduleCorrect) {
        System.debug('   ✅ PaymentStatus 자동 생성: 정상 (분기별 4회, 각 ₩' + expectedAmount.format() + ')');
    } else {
        System.debug('   ❌ PaymentStatus 자동 생성: 문제 있음');
    }
    
    // 4. Slack 채널 정보 검토
    System.debug('');
    System.debug('💬 STEP 4: Slack 채널 정보 검토');
    System.debug('   Slack Channel ID: ' + (String.isBlank(targetOrder.Slack_Channel_ID__c) ? '없음' : targetOrder.Slack_Channel_ID__c));
    System.debug('   Slack Channel Name: ' + (String.isBlank(targetOrder.Slack_Channel_Name__c) ? '없음' : targetOrder.Slack_Channel_Name__c));
    System.debug('   Slack Notification Status: ' + (String.isBlank(targetOrder.Slack_Notification_Status__c) ? 'Not Created' : targetOrder.Slack_Notification_Status__c));
    
    // 화면에서 보이는 정보와 비교
    Boolean slackChannelIdExists = String.isNotBlank(targetOrder.Slack_Channel_ID__c);
    Boolean slackChannelNameExists = String.isNotBlank(targetOrder.Slack_Channel_Name__c);
    String slackStatus = targetOrder.Slack_Notification_Status__c;
    
    if (slackChannelIdExists && slackChannelNameExists) {
        if (slackStatus == 'Created') {
            System.debug('   ✅ Slack 채널: 완전히 생성됨');
        } else if (slackStatus == 'Not Created') {
            System.debug('   ⚠️ Slack 채널: 정보는 있지만 Status가 "Not Created" (불일치)');
        } else {
            System.debug('   🔄 Slack 채널: 처리 중');
        }
    } else if (slackChannelNameExists) {
        System.debug('   ⚠️ Slack 채널: 이름만 있음 (ID 누락)');
    } else {
        System.debug('   ❌ Slack 채널: 생성되지 않음');
    }
    
    // 5. PDF 파일 생성 검토
    System.debug('');
    System.debug('📄 STEP 5: PDF 파일 생성 검토');
    List<ContentDocumentLink> pdfFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension,
               ContentDocument.CreatedDate, ContentDocument.ContentSize, ContentDocument.Description
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('   총 PDF 파일: ' + pdfFiles.size() + '개');
    
    if (pdfFiles.size() == 0) {
        System.debug('   ❌ PDF 파일: 없음 (Notes & Attachments 비어있음)');
    } else {
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
            
            System.debug('   ✅ ' + pdf.ContentDocument.Title + '.pdf' + fileType);
            System.debug('     생성일: ' + pdf.ContentDocument.CreatedDate.format() + 
                         ', 크기: ' + (pdf.ContentDocument.ContentSize / 1024) + 'KB');
            if (String.isNotBlank(pdf.ContentDocument.Description)) {
                System.debug('     설명: ' + pdf.ContentDocument.Description);
            }
        }
        
        if (productPDFExists) {
            System.debug('   ✅ Order Product 상세서 PDF: 존재');
        } else {
            System.debug('   ❌ Order Product 상세서 PDF: 누락');
        }
    }
    
    // 6. Activity Timeline 검토
    System.debug('');
    System.debug('💬 STEP 6: Activity Timeline (Chatter) 검토');
    List<FeedItem> chatterPosts = [
        SELECT Id, Body, CreatedDate, CreatedBy.Name, Type
        FROM FeedItem 
        WHERE ParentId = :targetOrder.Id
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
    
    System.debug('   총 Chatter 포스트: ' + chatterPosts.size() + '개');
    
    if (chatterPosts.size() == 0) {
        System.debug('   ❌ Activity Timeline: 비어있음 (No activities to show)');
    } else {
        Boolean automationPostExists = false;
        for (FeedItem post : chatterPosts) {
            String bodyPreview = post.Body.length() > 50 ? post.Body.substring(0, 50) + '...' : post.Body;
            System.debug('   • ' + post.CreatedDate.format() + ' by ' + post.CreatedBy.Name + ': ' + bodyPreview);
            
            if (post.Body.contains('자동화') || post.Body.contains('automation')) {
                automationPostExists = true;
            }
        }
        
        if (automationPostExists) {
            System.debug('   ✅ 자동화 관련 포스트: 존재');
        } else {
            System.debug('   ⚠️ 자동화 관련 포스트: 없음');
        }
    }
    
    // 7. 전체 자동화 시스템 상태 평가
    System.debug('');
    System.debug('📊 STEP 7: 전체 자동화 시스템 상태 평가');
    
    int successCount = 0;
    int totalChecks = 6;
    
    // 체크 1: Order 기본 상태
    if (targetOrder.Status == 'Activated' && targetOrder.TotalAmount > 0) {
        System.debug('   ✅ Order 기본 상태: 정상');
        successCount++;
    } else {
        System.debug('   ❌ Order 기본 상태: 문제');
    }
    
    // 체크 2: Order Products
    if (!targetOrder.OrderItems.isEmpty()) {
        System.debug('   ✅ Order Products: 정상 (' + targetOrder.OrderItems.size() + '개)');
        successCount++;
    } else {
        System.debug('   ❌ Order Products: 없음');
    }
    
    // 체크 3: PaymentStatus 자동 생성
    if (paymentStatuses.size() == 4 && paymentScheduleCorrect) {
        System.debug('   ✅ PaymentStatus 자동 생성: 정상');
        successCount++;
    } else {
        System.debug('   ❌ PaymentStatus 자동 생성: 문제');
    }
    
    // 체크 4: Slack 채널 정보
    if (slackChannelNameExists && slackChannelIdExists) {
        System.debug('   ✅ Slack 채널 정보: 정상');
        successCount++;
    } else if (slackChannelNameExists) {
        System.debug('   ⚠️ Slack 채널 정보: 부분 정상 (이름만 있음)');
        successCount += 0.5;
    } else {
        System.debug('   ❌ Slack 채널 정보: 누락');
    }
    
    // 체크 5: PDF 파일 생성
    if (pdfFiles.size() > 0) {
        System.debug('   ✅ PDF 파일 생성: 정상');
        successCount++;
    } else {
        System.debug('   ❌ PDF 파일 생성: 누락');
    }
    
    // 체크 6: Chatter 알림
    if (chatterPosts.size() > 0) {
        System.debug('   ✅ Chatter 알림: 정상');
        successCount++;
    } else {
        System.debug('   ❌ Chatter 알림: 누락');
    }
    
    Double successRate = (Double)successCount / totalChecks * 100;
    System.debug('');
    System.debug('🎯 전체 자동화 성공률: ' + successRate.intValue() + '% (' + successCount + '/' + totalChecks + ')');
    
    // 8. 현재 상태 기반 진단
    System.debug('');
    System.debug('🔬 STEP 8: 현재 상태 기반 진단');
    
    if (slackChannelIdExists && slackChannelNameExists && pdfFiles.size() == 0 && chatterPosts.size() == 0) {
        System.debug('   📝 진단: Slack 정보는 업데이트되었지만 PDF와 Chatter는 누락');
        System.debug('   💡 추정: 자동화 시스템이 부분적으로 실행되었으나 완료되지 않음');
        System.debug('   🔧 해결: 수동 완료 실행 필요');
    } else if (successRate >= 80) {
        System.debug('   📝 진단: 자동화 시스템 정상 작동');
    } else if (successRate >= 60) {
        System.debug('   📝 진단: 자동화 시스템 부분 작동');
    } else {
        System.debug('   📝 진단: 자동화 시스템 문제 있음');
    }
    
    // 9. 즉시 조치 방안
    System.debug('');
    System.debug('⚡ STEP 9: 즉시 조치 방안');
    
    if (pdfFiles.size() == 0) {
        System.debug('   🔧 PDF 생성 필요: scripts/apex/execute_order_00000142_automation.apex 실행');
    }
    
    if (chatterPosts.size() == 0) {
        System.debug('   🔧 Chatter 알림 필요: 수동 포스트 생성 또는 자동화 재실행');
    }
    
    if (targetOrder.Slack_Notification_Status__c == 'Not Created' && slackChannelNameExists) {
        System.debug('   🔧 Slack Status 업데이트 필요: Status를 "Created"로 변경');
    }
    
    System.debug('');
    System.debug('✅ =====Order 00000142 단계별 검토 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 검토 중 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// Order 00000141 자동화 시스템 실제 실행 (비동기)
System.debug('🚀 =====Order 00000141 실제 자동화 시스템 실행=====');

try {
    // 1. Order 00000141 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name, TotalAmount, Status
        FROM Order 
        WHERE OrderNumber = '00000141'
        AND Status = 'Activated'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000141 (Activated)을 찾을 수 없습니다.');
        
        // Draft 상태 Order 확인
        List<Order> draftOrders = [
            SELECT Id, OrderNumber, Status
            FROM Order 
            WHERE OrderNumber = '00000141'
            LIMIT 1
        ];
        
        if (!draftOrders.isEmpty()) {
            System.debug('📋 Order 00000141 상태: ' + draftOrders[0].Status);
            System.debug('   Activated 상태의 Order만 자동화 시스템이 동작합니다.');
        }
        return;
    }
    
    Order targetOrder = orders[0];
    System.debug('📋 Order: ' + targetOrder.OrderNumber + ' (' + targetOrder.Account.Name + ')');
    System.debug('   Status: ' + targetOrder.Status);
    System.debug('   Amount: ₩' + targetOrder.TotalAmount.format());
    
    // 2. OrderItem 존재 확인
    List<OrderItem> orderItems = [
        SELECT Id, Product2.Name, Quantity, TotalPrice
        FROM OrderItem 
        WHERE OrderId = :targetOrder.Id
    ];
    
    System.debug('   Order Products: ' + orderItems.size() + '개');
    if (orderItems.isEmpty()) {
        System.debug('❌ Order에 Product가 없습니다. 자동화를 실행할 수 없습니다.');
        return;
    }
    
    for (OrderItem item : orderItems) {
        System.debug('   • ' + item.Product2.Name + ' (Qty: ' + item.Quantity + 
                     ', Total: ₩' + item.TotalPrice.format() + ')');
    }
    
    // 3. 현재 자동화 상태 확인
    System.debug('');
    System.debug('📊 현재 자동화 상태 확인:');
    
    // PDF 파일 확인
    List<ContentDocumentLink> existingPDFs = [
        SELECT ContentDocument.Title, ContentDocument.CreatedDate
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        AND ContentDocument.FileExtension = 'pdf'
        AND ContentDocument.Title LIKE '%Product%상세서%'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('   기존 Product 상세서 PDF: ' + existingPDFs.size() + '개');
    
    // Slack 상태 확인
    Order orderWithSlack = [
        SELECT Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c
        FROM Order 
        WHERE Id = :targetOrder.Id
    ];
    
    System.debug('   Slack 채널 상태: ' + 
                 (String.isBlank(orderWithSlack.Slack_Notification_Status__c) ? 
                  'Not Created' : orderWithSlack.Slack_Notification_Status__c));
    
    // 4. 자동화 시스템 실행
    System.debug('');
    System.debug('🤖 OrderProductAutomationService 실행 중...');
    
    Set<Id> orderIds = new Set<Id>{ targetOrder.Id };
    
    // @future 메서드 호출 (비동기 실행)
    OrderProductAutomationService.processOrderProductAutomation(orderIds);
    
    System.debug('✅ 자동화 시스템이 비동기로 시작되었습니다.');
    System.debug('');
    System.debug('📋 처리될 작업:');
    System.debug('   1. Order Product 상세서 PDF 자동 생성');
    System.debug('   2. Slack 채널 자동 생성 (#' + targetOrder.OrderNumber + ')');
    System.debug('   3. Files에 PDF 자동 첨부');
    System.debug('   4. Chatter 완료 알림 포스트');
    System.debug('');
    System.debug('⏰ 처리 시간: 약 30초~1분 소요');
    System.debug('📍 결과 확인: Order 00000141의 Notes & Attachments 및 Chatter');
    
    System.debug('');
    System.debug('✅ =====Order 00000141 자동화 시스템 실행 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 자동화 시스템 실행 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

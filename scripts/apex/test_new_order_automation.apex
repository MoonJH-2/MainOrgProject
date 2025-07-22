// 신규 Order 생성 시 자동화 시스템 전체 테스트
System.debug('🆕 =====신규 Order 생성 자동화 시스템 테스트=====');

try {
    // 1. 테스트용 Account 조회 또는 생성
    List<Account> testAccounts = [
        SELECT Id, Name FROM Account 
        WHERE Name = '자동화테스트고객' 
        LIMIT 1
    ];
    
    Account testAccount;
    if (testAccounts.isEmpty()) {
        testAccount = new Account();
        testAccount.Name = '자동화테스트고객';
        testAccount.Type = 'Customer';
        insert testAccount;
        System.debug('✅ 테스트 Account 생성: ' + testAccount.Name);
    } else {
        testAccount = testAccounts[0];
        System.debug('📋 기존 테스트 Account 사용: ' + testAccount.Name);
    }
    
    // 2. 테스트용 Product 조회
    List<Product2> testProducts = [
        SELECT Id, Name, ProductCode FROM Product2 
        WHERE ProductCode = 'CAR-PLT'
        LIMIT 1
    ];
    
    if (testProducts.isEmpty()) {
        System.debug('❌ 테스트용 Product (CAR-PLT)를 찾을 수 없습니다.');
        return;
    }
    
    Product2 testProduct = testProducts[0];
    System.debug('📦 테스트 Product: ' + testProduct.Name + ' (' + testProduct.ProductCode + ')');
    
    // 3. PricebookEntry 조회
    List<PricebookEntry> pricebookEntries = [
        SELECT Id, UnitPrice FROM PricebookEntry 
        WHERE Product2Id = :testProduct.Id 
        AND Pricebook2Id = :Test.getStandardPricebookId()
        AND IsActive = true
        LIMIT 1
    ];
    
    if (pricebookEntries.isEmpty()) {
        System.debug('❌ 테스트용 PricebookEntry를 찾을 수 없습니다.');
        return;
    }
    
    PricebookEntry pbe = pricebookEntries[0];
    System.debug('💰 Unit Price: ₩' + pbe.UnitPrice.format());
    
    // 4. 신규 Order 생성
    Order newOrder = new Order();
    newOrder.AccountId = testAccount.Id;
    newOrder.EffectiveDate = Date.today();
    newOrder.Status = 'Draft';
    newOrder.Payment_Method__c = '월별';
    newOrder.Pricebook2Id = Test.getStandardPricebookId();
    
    insert newOrder;
    
    System.debug('✅ 신규 Order 생성: ' + newOrder.Id);
    
    // Order Number 조회
    Order insertedOrder = [SELECT OrderNumber FROM Order WHERE Id = :newOrder.Id];
    System.debug('   Order Number: ' + insertedOrder.OrderNumber);
    
    // 5. OrderItem 생성 (이 시점에서 자동화 트리거됨)
    System.debug('');
    System.debug('🛒 OrderItem 생성 중... (자동화 트리거 예상)');
    
    OrderItem newOrderItem = new OrderItem();
    newOrderItem.OrderId = newOrder.Id;
    newOrderItem.Product2Id = testProduct.Id;
    newOrderItem.PricebookEntryId = pbe.Id;
    newOrderItem.Quantity = 50;
    newOrderItem.UnitPrice = pbe.UnitPrice;
    
    insert newOrderItem;
    
    System.debug('✅ OrderItem 생성 완료');
    System.debug('   Product: ' + testProduct.Name);
    System.debug('   Quantity: 50');
    System.debug('   Total: ₩' + (pbe.UnitPrice * 50).format());
    
    // 6. Order 상태 확인 (TotalAmount 업데이트 확인)
    Order updatedOrder = [
        SELECT Id, OrderNumber, TotalAmount, Status, 
               Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c
        FROM Order 
        WHERE Id = :newOrder.Id
    ];
    
    System.debug('');
    System.debug('📊 OrderItem 생성 후 Order 상태:');
    System.debug('   Order Number: ' + updatedOrder.OrderNumber);
    System.debug('   Total Amount: ₩' + updatedOrder.TotalAmount.format());
    System.debug('   Status: ' + updatedOrder.Status);
    
    // 7. Order가 Draft 상태면 Activated로 변경 (자동화 트리거)
    if (updatedOrder.Status == 'Draft') {
        System.debug('');
        System.debug('🔄 Order를 Activated로 변경 중... (자동화 트리거 예상)');
        
        Order orderToActivate = new Order();
        orderToActivate.Id = updatedOrder.Id;
        orderToActivate.Status = 'Activated';
        
        update orderToActivate;
        
        System.debug('✅ Order Status 변경: Draft → Activated');
    }
    
    // 8. 자동화 결과 확인 (약간의 지연 후)
    System.debug('');
    System.debug('⏰ 자동화 시스템 처리 대기 중... (비동기 처리)');
    
    // 최종 Order 상태 조회
    Order finalOrder = [
        SELECT Id, OrderNumber, TotalAmount, Status, 
               Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c
        FROM Order 
        WHERE Id = :newOrder.Id
    ];
    
    System.debug('');
    System.debug('📋 최종 Order 상태:');
    System.debug('   Order Number: ' + finalOrder.OrderNumber);
    System.debug('   Status: ' + finalOrder.Status);
    System.debug('   Total Amount: ₩' + finalOrder.TotalAmount.format());
    System.debug('   Slack Status: ' + 
                 (String.isBlank(finalOrder.Slack_Notification_Status__c) ? 
                  'Processing...' : finalOrder.Slack_Notification_Status__c));
    
    // 9. 예상 결과 안내
    System.debug('');
    System.debug('🎯 예상되는 자동화 결과:');
    System.debug('   1. PaymentStatus 자동 생성 (월별 분할)');
    System.debug('   2. Order Product 상세서 PDF 자동 생성');
    System.debug('   3. Slack 채널 자동 생성 (#' + finalOrder.OrderNumber + ')');
    System.debug('   4. PDF가 Notes & Attachments에 자동 첨부');
    System.debug('   5. Chatter에 완료 알림 포스트');
    
    System.debug('');
    System.debug('📍 확인 방법:');
    System.debug('   • Order ' + finalOrder.OrderNumber + ' 상세 페이지 접속');
    System.debug('   • Notes & Attachments 섹션에서 새 PDF 확인');
    System.debug('   • Chatter에서 자동화 완료 메시지 확인');
    System.debug('   • PaymentStatus Related List 확인');
    
    System.debug('');
    System.debug('✅ =====신규 Order 자동화 테스트 완료=====');
    System.debug('📝 생성된 Order Number: ' + finalOrder.OrderNumber);
    
} catch (Exception e) {
    System.debug('❌ 신규 Order 자동화 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

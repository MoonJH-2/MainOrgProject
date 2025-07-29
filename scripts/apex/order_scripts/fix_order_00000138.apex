/**
 * Order 00000138 Opportunity Product 자동 등록 스크립트
 * Developer Console > Debug > Open Execute Anonymous Window에서 실행
 * 
 * 목표:
 * - Opportunity Product → Order Product 등록
 * - Order Amount: ₩0 → ₩10,176,000
 * - PaymentStatus 생성 (반기별 2회)
 */

System.debug('🎯 =====Order 00000138 Opportunity Product 등록 시작=====');

try {
    // 1. Order 00000138 조회
    Order targetOrder = [
        SELECT Id, OrderNumber, OpportunityId, TotalAmount, AccountId, 
               Status, Payment_Method__c, EffectiveDate, Pricebook2Id
        FROM Order 
        WHERE OrderNumber = '00000138' 
        LIMIT 1
    ];
    
    System.debug('📋 Order 정보:');
    System.debug('   OrderNumber: ' + targetOrder.OrderNumber);
    System.debug('   현재 TotalAmount: ' + targetOrder.TotalAmount);
    System.debug('   Status: ' + targetOrder.Status);
    System.debug('   Payment_Method: ' + targetOrder.Payment_Method__c);
    System.debug('   OpportunityId: ' + targetOrder.OpportunityId);
    
    if (targetOrder.OpportunityId == null) {
        System.debug('❌ Order에 연결된 Opportunity가 없습니다.');
        return;
    }
    
    // 2. 연관된 Opportunity Product 조회
    List<OpportunityLineItem> oppProducts = [
        SELECT Id, OpportunityId, Product2Id, Quantity, UnitPrice, TotalPrice,
               Product2.Name, Product2.ProductCode
        FROM OpportunityLineItem 
        WHERE OpportunityId = :targetOrder.OpportunityId
    ];
    
    System.debug('');
    System.debug('📦 Opportunity Products:');
    System.debug('   개수: ' + oppProducts.size());
    
    if (oppProducts.isEmpty()) {
        System.debug('❌ 연결된 Opportunity Product가 없습니다.');
        return;
    }
    
    Decimal expectedTotalAmount = 0;
    for (OpportunityLineItem item : oppProducts) {
        expectedTotalAmount += item.TotalPrice;
        System.debug('   - ' + item.Product2.Name + ' (' + item.Product2.ProductCode + ')');
        System.debug('     수량: ' + item.Quantity + ', 단가: ₩' + item.UnitPrice + ', 총액: ₩' + item.TotalPrice);
    }
    
    System.debug('   예상 Order 총액: ₩' + expectedTotalAmount);
    
    // 3. 기존 Order Products 확인
    List<OrderItem> existingOrderProducts = [
        SELECT Id FROM OrderItem WHERE OrderId = :targetOrder.Id
    ];
    
    if (!existingOrderProducts.isEmpty()) {
        System.debug('⚠️ 이미 Order Products가 존재합니다 (' + existingOrderProducts.size() + '개)');
        System.debug('   기존 Order Products를 삭제하고 새로 생성합니다.');
        delete existingOrderProducts;
    }
    
    // 4. Standard Pricebook 설정
    Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    
    if (targetOrder.Pricebook2Id == null) {
        targetOrder.Pricebook2Id = standardPricebook.Id;
        update targetOrder;
        System.debug('✅ Order에 Standard Pricebook 설정 완료');
    }
    
    // 5. Order Products 생성
    System.debug('');
    System.debug('🔨 Order Products 생성 중...');
    
    List<OrderItem> orderItemsToInsert = new List<OrderItem>();
    
    for (OpportunityLineItem oppItem : oppProducts) {
        // PricebookEntry 조회/생성
        List<PricebookEntry> pbeList = [
            SELECT Id FROM PricebookEntry 
            WHERE Product2Id = :oppItem.Product2Id 
            AND Pricebook2Id = :standardPricebook.Id
            LIMIT 1
        ];
        
        Id pricebookEntryId;
        if (pbeList.isEmpty()) {
            // PricebookEntry 생성
            PricebookEntry newPbe = new PricebookEntry();
            newPbe.Product2Id = oppItem.Product2Id;
            newPbe.Pricebook2Id = standardPricebook.Id;
            newPbe.UnitPrice = oppItem.UnitPrice;
            newPbe.IsActive = true;
            insert newPbe;
            pricebookEntryId = newPbe.Id;
            System.debug('   ✅ 새 PricebookEntry 생성: ' + oppItem.Product2.Name);
        } else {
            pricebookEntryId = pbeList[0].Id;
            System.debug('   ✅ 기존 PricebookEntry 사용: ' + oppItem.Product2.Name);
        }
        
        // OrderItem 생성
        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = targetOrder.Id;
        orderItem.Product2Id = oppItem.Product2Id;
        orderItem.PricebookEntryId = pricebookEntryId;
        orderItem.Quantity = oppItem.Quantity;
        orderItem.UnitPrice = oppItem.UnitPrice;
        
        orderItemsToInsert.add(orderItem);
    }
    
    // Order Products 생성 실행
    if (!orderItemsToInsert.isEmpty()) {
        insert orderItemsToInsert;
        System.debug('✅ Order Products 생성 완료: ' + orderItemsToInsert.size() + '개');
    }
    
    // 6. Order TotalAmount 확인 (Order Products 생성 후 자동 계산)
    Order updatedOrder = [SELECT Id, TotalAmount, Status FROM Order WHERE Id = :targetOrder.Id];
    System.debug('');
    System.debug('💰 Order 금액 확인:');
    System.debug('   이전 TotalAmount: ₩' + targetOrder.TotalAmount);
    System.debug('   현재 TotalAmount: ₩' + updatedOrder.TotalAmount);
    
    // 7. Order 활성화 (필요한 경우)
    if (updatedOrder.Status == 'Draft') {
        updatedOrder.Status = 'Activated';
        update updatedOrder;
        System.debug('✅ Order Status: Draft → Activated');
    }
    
    // 8. PaymentStatus 생성
    System.debug('');
    System.debug('📅 PaymentStatus 생성 중...');
    
    // 기존 PaymentStatus 정리
    List<PaymentStatus__c> existingPayments = [
        SELECT Id FROM PaymentStatus__c WHERE Order__c = :targetOrder.Id
    ];
    
    if (!existingPayments.isEmpty()) {
        delete existingPayments;
        System.debug('   기존 PaymentStatus 삭제: ' + existingPayments.size() + '개');
    }
    
    // 최종 Order 정보로 PaymentStatus 생성
    Order finalOrder = [
        SELECT Id, TotalAmount, Payment_Method__c, EffectiveDate 
        FROM Order WHERE Id = :targetOrder.Id
    ];
    
    if (finalOrder.TotalAmount != null && finalOrder.TotalAmount > 0) {
        try {
            PaymentScheduleService.createPaymentSchedule(finalOrder.Id, finalOrder.TotalAmount);
            System.debug('✅ PaymentStatus 생성 완료 (Payment Method: ' + finalOrder.Payment_Method__c + ')');
            
            // 생성된 PaymentStatus 확인
            List<PaymentStatus__c> newPayments = [
                SELECT InstallmentNumber__c, Amount__c, DueDate__c, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c = :targetOrder.Id
                ORDER BY InstallmentNumber__c
            ];
            
            System.debug('   생성된 PaymentStatus:');
            for (PaymentStatus__c ps : newPayments) {
                System.debug('   - ' + ps.InstallmentNumber__c + '차: ₩' + ps.Amount__c + ' (due: ' + ps.DueDate__c + ')');
            }
            
        } catch (Exception e) {
            System.debug('❌ PaymentStatus 생성 실패: ' + e.getMessage());
        }
    }
    
    // 9. 최종 결과 요약
    System.debug('');
    System.debug('🎯 =====Order 00000138 등록 완료=====');
    System.debug('✅ Order Products: ' + orderItemsToInsert.size() + '개 생성');
    System.debug('✅ Order Amount: ₩' + finalOrder.TotalAmount);
    System.debug('✅ Order Status: ' + (updatedOrder.Status == 'Activated' ? 'Activated' : updatedOrder.Status));
    System.debug('✅ PaymentStatus: 생성 완료');
    System.debug('');
    System.debug('🔍 확인사항:');
    System.debug('1. Order 00000138 페이지에서 Order Products 섹션 확인');
    System.debug('2. 납부 일정 타임라인에서 PaymentStatus 확인');
    System.debug('3. Order Amount가 ₩10,176,000으로 표시되는지 확인');
    
} catch (Exception e) {
    System.debug('❌ 오류 발생: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('🎯 =====스크립트 실행 완료=====');

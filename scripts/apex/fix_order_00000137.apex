/**
 * Order 00000137 즉시 보정 스크립트
 * Developer Console > Debug > Open Execute Anonymous Window에서 실행
 */

// 1. 특정 Order 조회
Order targetOrder = [
    SELECT Id, OrderNumber, OpportunityId, TotalAmount, AccountId 
    FROM Order 
    WHERE OrderNumber = '00000137' 
    LIMIT 1
];

System.debug('보정 대상 Order: ' + targetOrder.OrderNumber);
System.debug('현재 Order Amount: ' + targetOrder.TotalAmount);

// 2. 연관된 Opportunity Product 조회
List<OpportunityLineItem> oppProducts = [
    SELECT Id, OpportunityId, Product2Id, Quantity, UnitPrice, TotalPrice,
           Product2.Name, Product2.ProductCode
    FROM OpportunityLineItem 
    WHERE OpportunityId = :targetOrder.OpportunityId
];

System.debug('Opportunity Products 개수: ' + oppProducts.size());

Decimal correctTotalAmount = 0;
for (OpportunityLineItem item : oppProducts) {
    correctTotalAmount += item.TotalPrice;
    System.debug('제품: ' + item.Product2.Name + ', 수량: ' + item.Quantity + ', 단가: ' + item.UnitPrice + ', 총액: ' + item.TotalPrice);
}

System.debug('정확한 총액: ' + correctTotalAmount);

// 3. Order Product가 이미 있는지 확인
List<OrderItem> existingOrderProducts = [
    SELECT Id FROM OrderItem WHERE OrderId = :targetOrder.Id
];

if (!existingOrderProducts.isEmpty()) {
    System.debug('이미 Order Products가 존재합니다. 개수: ' + existingOrderProducts.size());
} else {
    System.debug('Order Products가 없습니다. 생성이 필요합니다.');
    
    // 4. Standard Price Book 조회
    Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    
    // 5. Order Products 생성
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
            System.debug('새 PricebookEntry 생성: ' + newPbe.Id);
        } else {
            pricebookEntryId = pbeList[0].Id;
            System.debug('기존 PricebookEntry 사용: ' + pricebookEntryId);
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
    
    // Order Products 생성
    if (!orderItemsToInsert.isEmpty()) {
        insert orderItemsToInsert;
        System.debug('Order Products 생성 완료: ' + orderItemsToInsert.size() + '개');
    }
}

// 6. Order에 Pricebook2 설정 및 Order Products 생성
if (!existingOrderProducts.isEmpty()) {
    System.debug('이미 Order Products가 존재합니다. 개수: ' + existingOrderProducts.size());
} else {
    System.debug('Order Products가 없습니다. 생성이 필요합니다.');
    
    // 4. Standard Price Book 조회
    Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    
    // Order에 Pricebook2 설정
    if (targetOrder.Pricebook2Id == null) {
        targetOrder.Pricebook2Id = standardPricebook.Id;
        update targetOrder;
        System.debug('Order에 Standard Pricebook 설정 완료');
    }
    
    // 5. Order Products 생성
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
            System.debug('새 PricebookEntry 생성: ' + newPbe.Id);
        } else {
            pricebookEntryId = pbeList[0].Id;
            System.debug('기존 PricebookEntry 사용: ' + pricebookEntryId);
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
    
    // Order Products 생성
    if (!orderItemsToInsert.isEmpty()) {
        insert orderItemsToInsert;
        System.debug('Order Products 생성 완료: ' + orderItemsToInsert.size() + '개');
    }
}

// 7. Order의 TotalAmount 확인 (Order Products 생성 후 자동 계산됨)
Order updatedOrder = [SELECT Id, TotalAmount FROM Order WHERE Id = :targetOrder.Id];
System.debug('업데이트된 Order Amount: ' + updatedOrder.TotalAmount);

// 8. PaymentStatus 재생성 (Order TotalAmount 기준)
if (updatedOrder.TotalAmount != null && updatedOrder.TotalAmount > 0) {
    List<PaymentStatus__c> existingPayments = [
        SELECT Id FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
    ];
    
    if (!existingPayments.isEmpty()) {
        delete existingPayments;
        System.debug('기존 PaymentStatus 삭제: ' + existingPayments.size() + '개');
    }
    
    // 새로운 PaymentStatus 생성
    PaymentScheduleService.createPaymentSchedule(targetOrder.Id, updatedOrder.TotalAmount);
    System.debug('새로운 PaymentStatus 생성 완료');
} else {
    System.debug('Order TotalAmount가 설정되지 않았습니다.');
}

System.debug('=== Order 00000137 보정 완료 ===');

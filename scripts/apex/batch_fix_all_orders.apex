/**
 * 전체 Order Product 누락 건 일괄 보정 배치 실행 스크립트
 * Developer Console > Debug > Open Execute Anonymous Window에서 실행
 */

// 1. Order Product가 누락된 Order 개수 확인
List<Order> ordersWithoutProducts = [
    SELECT Id, OrderNumber, OpportunityId, TotalAmount
    FROM Order 
    WHERE OpportunityId != null
    AND Id NOT IN (SELECT OrderId FROM OrderItem WHERE OrderId != null)
];

System.debug('Order Product가 누락된 Order 개수: ' + ordersWithoutProducts.size());

for (Order ord : ordersWithoutProducts) {
    System.debug('- Order: ' + ord.OrderNumber + ', Amount: ' + ord.TotalAmount);
}

// 2. 배치 실행
if (!ordersWithoutProducts.isEmpty()) {
    System.debug('OrderProductCorrectionBatch 실행 시작...');
    
    OrderProductCorrectionBatch batch = new OrderProductCorrectionBatch();
    Database.BatchableContext context = null;
    
    // 소량이므로 직접 실행 (배치 큐 사용 안함)
    batch.execute(context, ordersWithoutProducts);
    
    System.debug('OrderProductCorrectionBatch 실행 완료');
} else {
    System.debug('보정이 필요한 Order가 없습니다.');
}

// 3. 결과 확인
List<Order> correctedOrders = [
    SELECT Id, OrderNumber, TotalAmount,
           (SELECT Id, Product2.Name, Quantity, UnitPrice FROM OrderItems)
    FROM Order 
    WHERE Id IN :ordersWithoutProducts
];

System.debug('=== 보정 결과 ===');
for (Order ord : correctedOrders) {
    System.debug('Order: ' + ord.OrderNumber + ', Amount: ' + ord.TotalAmount);
    System.debug('Order Products: ' + ord.OrderItems.size() + '개');
    
    for (OrderItem item : ord.OrderItems) {
        System.debug('- ' + item.Product2.Name + ' x ' + item.Quantity + ' = ' + item.UnitPrice);
    }
}

System.debug('=== 전체 Order Product 보정 완료 ===');

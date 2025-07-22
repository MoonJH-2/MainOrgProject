/**
 * Draft 상태이지만 Order Products가 있는 Order들을 일괄 활성화하는 스크립트
 * Developer Console > Debug > Open Execute Anonymous Window에서 실행
 */

System.debug('🚀 =====Draft Order 일괄 활성화 시작=====');

try {
    // 1. Draft 상태이지만 Order Products가 있는 Order 조회
    List<Order> draftOrdersWithProducts = [
        SELECT Id, OrderNumber, TotalAmount, Status
        FROM Order 
        WHERE Status = 'Draft'
        AND TotalAmount > 0
        AND Id IN (SELECT OrderId FROM OrderItem WHERE OrderId != null)
    ];
    
    System.debug('📊 활성화 대상 Order 개수: ' + draftOrdersWithProducts.size());
    
    if (draftOrdersWithProducts.isEmpty()) {
        System.debug('✅ 활성화가 필요한 Draft Order가 없습니다.');
        return;
    }
    
    // 상세 현황 출력
    System.debug('📋 활성화 대상 Order 목록:');
    for (Order ord : draftOrdersWithProducts) {
        System.debug('   - ' + ord.OrderNumber + ' (Amount: ₩' + ord.TotalAmount + ')');
    }
    
    // 2. Order 상태를 Draft → Activated로 변경
    System.debug('');
    System.debug('🔄 Order 상태 변경 중...');
    
    List<Order> ordersToUpdate = new List<Order>();
    
    for (Order ord : draftOrdersWithProducts) {
        Order orderToUpdate = new Order();
        orderToUpdate.Id = ord.Id;
        orderToUpdate.Status = 'Activated';
        ordersToUpdate.add(orderToUpdate);
    }
    
    // 일괄 업데이트 실행
    update ordersToUpdate;
    
    System.debug('✅ Order 상태 변경 완료: ' + ordersToUpdate.size() + '개');
    
    // 3. 변경 결과 확인
    List<Order> updatedOrders = [
        SELECT Id, OrderNumber, Status, TotalAmount
        FROM Order 
        WHERE Id IN :ordersToUpdate
    ];
    
    System.debug('');
    System.debug('📋 변경 결과:');
    for (Order ord : updatedOrders) {
        System.debug('   ✅ ' + ord.OrderNumber + ': ' + ord.Status + ' (₩' + ord.TotalAmount + ')');
    }
    
    // 4. 전체 현황 확인
    List<Order> remainingDraftOrders = [
        SELECT Id, OrderNumber
        FROM Order 
        WHERE Status = 'Draft'
        AND TotalAmount > 0
        AND Id IN (SELECT OrderId FROM OrderItem WHERE OrderId != null)
    ];
    
    System.debug('');
    System.debug('📊 최종 현황:');
    System.debug('   활성화 완료: ' + ordersToUpdate.size() + '개');
    System.debug('   남은 Draft Order: ' + remainingDraftOrders.size() + '개');
    
    if (remainingDraftOrders.isEmpty()) {
        System.debug('✅ 모든 해당 Order가 성공적으로 활성화되었습니다.');
    } else {
        System.debug('⚠️ 일부 Order가 여전히 Draft 상태입니다:');
        for (Order ord : remainingDraftOrders) {
            System.debug('   - ' + ord.OrderNumber);
        }
    }
    
    System.debug('');
    System.debug('🔍 확인사항:');
    System.debug('1. 각 Order 페이지에서 Status가 Activated로 변경되었는지 확인');
    System.debug('2. 납부 일정 타임라인이 정상적으로 표시되는지 확인');
    System.debug('3. PaymentStatus 관련 자동화가 정상 작동하는지 확인');
    
} catch (Exception e) {
    System.debug('❌ 일괄 활성화 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('🚀 =====Draft Order 일괄 활성화 완료=====');

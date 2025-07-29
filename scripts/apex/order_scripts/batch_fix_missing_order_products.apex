/**
 * Order Product 누락 일괄 보정 배치 실행 스크립트
 * Developer Console > Debug > Open Execute Anonymous Window에서 실행
 */

System.debug('📦 =====Order Product 누락 일괄 보정 배치 실행=====');

try {
    // 1. 현재 상황 파악
    List<Order> ordersWithoutProducts = [
        SELECT Id, OrderNumber, OpportunityId, TotalAmount, Status
        FROM Order 
        WHERE OpportunityId != null
        AND Id NOT IN (SELECT OrderId FROM OrderItem WHERE OrderId != null)
        AND TotalAmount <= 0
    ];
    
    System.debug('📊 Order Product가 누락된 Order 개수: ' + ordersWithoutProducts.size());
    
    if (ordersWithoutProducts.isEmpty()) {
        System.debug('✅ 보정이 필요한 Order가 없습니다.');
        return;
    }
    
    // 상세 현황 출력
    System.debug('📋 보정 대상 Order 목록:');
    for (Order ord : ordersWithoutProducts) {
        System.debug('   - ' + ord.OrderNumber + ' (Amount: ₩' + ord.TotalAmount + ', Status: ' + ord.Status + ')');
    }
    
    // 2. 배치 실행
    System.debug('');
    System.debug('🚀 배치 실행 시작...');
    
    OrderProductMissingCorrectionBatch batch = new OrderProductMissingCorrectionBatch();
    Id batchJobId = Database.executeBatch(batch, 10); // 10개씩 처리
    
    System.debug('✅ 배치 실행 완료');
    System.debug('   Batch Job ID: ' + batchJobId);
    System.debug('   처리 예정 Order: ' + ordersWithoutProducts.size() + '개');
    
    // 3. 배치 상태 확인 방법 안내
    System.debug('');
    System.debug('🔍 배치 실행 상태 확인 방법:');
    System.debug('1. Setup > Apex Jobs에서 배치 진행 상황 확인');
    System.debug('2. 또는 아래 SOQL로 직접 확인:');
    System.debug('   SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors');
    System.debug('   FROM AsyncApexJob WHERE Id = \'' + batchJobId + '\'');
    
    // 4. 결과 확인용 스크립트 제공
    System.debug('');
    System.debug('📝 배치 완료 후 결과 확인 스크립트:');
    System.debug('// 남은 누락 Order 확인');
    System.debug('List<Order> remaining = [SELECT Id, OrderNumber FROM Order WHERE OpportunityId != null AND Id NOT IN (SELECT OrderId FROM OrderItem) AND TotalAmount <= 0];');
    System.debug('System.debug(\"남은 이슈: \" + remaining.size() + \"개\");');
    
} catch (Exception e) {
    System.debug('❌ 배치 실행 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('📦 =====배치 실행 스크립트 완료=====');

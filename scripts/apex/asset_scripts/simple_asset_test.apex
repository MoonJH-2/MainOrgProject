/**
 * 간단한 Asset 생성 테스트
 */

System.debug('=== 간단한 Asset 생성 테스트 ===');

// OrderAssetCreationService 클래스 테스트
try {
    // 테스트용 완납 확인 (가상 ID)
    System.debug('OrderAssetCreationService 클래스 로드 테스트...');
    
    // Order 목록 확인
    List<Order> allOrders = [SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount FROM Order LIMIT 5];
    System.debug('전체 Order 개수: ' + allOrders.size());
    
    for (Order ord : allOrders) {
        System.debug('- Order: ' + ord.OrderNumber + ', 고객: ' + ord.Account.Name);
        
        // PaymentStatus 확인
        List<PaymentStatus__c> payments = [
            SELECT Id, Status__c 
            FROM PaymentStatus__c 
            WHERE Order__c = :ord.Id 
            LIMIT 3
        ];
        
        System.debug('  PaymentStatus 개수: ' + payments.size());
        if (!payments.isEmpty()) {
            Integer completedCount = 0;
            for (PaymentStatus__c p : payments) {
                if (p.Status__c == '완납') {
                    completedCount++;
                }
            }
            System.debug('  완납된 PaymentStatus: ' + completedCount + '/' + payments.size());
            
            // 완납 상태 확인 테스트
            Boolean isFullyPaid = OrderAssetCreationService.isOrderFullyPaid(ord.Id);
            System.debug('  완납 상태: ' + isFullyPaid);
        }
    }
    
    // Asset 개수 확인
    Integer assetCount = [SELECT COUNT() FROM Asset];
    System.debug('현재 Asset 개수: ' + assetCount);
    
    System.debug('✅ Asset 시스템 기본 테스트 완료');
    
} catch (Exception e) {
    System.debug('❌ 테스트 오류: ' + e.getMessage());
}

System.debug('=== 테스트 완료 ===');

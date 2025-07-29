/**
 * Asset 수동 생성 테스트
 */

System.debug('=== Asset 수동 생성 테스트 시작 ===');

// 1. 첫 번째 Order 가져오기
List<Order> testOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount, Status
    FROM Order 
    LIMIT 1
];

if (testOrders.isEmpty()) {
    System.debug('❌ 테스트할 Order가 없습니다.');
} else {
    Order testOrder = testOrders[0];
    System.debug('테스트 Order: ' + testOrder.OrderNumber + ' (' + testOrder.Account.Name + ')');
    
    try {
        // 2. Asset 직접 생성 테스트
        Asset testAsset = new Asset();
        testAsset.Name = testOrder.Account.Name + ' - Order ' + testOrder.OrderNumber;
        testAsset.AccountId = testOrder.AccountId;
        testAsset.SerialNumber = testOrder.OrderNumber;
        testAsset.PurchaseDate = Date.today();
        testAsset.InstallDate = Date.today();
        testAsset.Status = 'Purchased';
        testAsset.Price = testOrder.TotalAmount;
        testAsset.Quantity = 1;
        testAsset.Description = 'Order ' + testOrder.OrderNumber + '에서 수동 생성된 테스트 Asset';
        
        insert testAsset;
        
        System.debug('✅ Asset 생성 성공!');
        System.debug('- Asset ID: ' + testAsset.Id);
        System.debug('- Asset Name: ' + testAsset.Name);
        System.debug('- Serial Number: ' + testAsset.SerialNumber);
        System.debug('- Price: ' + (testAsset.Price != null ? testAsset.Price.format() : '0') + '원');
        
        // 3. 생성된 Asset 조회 확인
        Asset createdAsset = [
            SELECT Id, Name, SerialNumber, AccountId, Account.Name, 
                   PurchaseDate, Status, Price, Description
            FROM Asset 
            WHERE Id = :testAsset.Id
        ];
        
        System.debug('생성된 Asset 정보:');
        System.debug('- ID: ' + createdAsset.Id);
        System.debug('- Name: ' + createdAsset.Name);
        System.debug('- Account: ' + createdAsset.Account.Name);
        System.debug('- Status: ' + createdAsset.Status);
        System.debug('- Purchase Date: ' + createdAsset.PurchaseDate);
        
        // 4. OrderAssetCreationService로 Asset 생성 테스트
        System.debug('\n=== OrderAssetCreationService 테스트 ===');
        
        // 기존 Asset 삭제
        delete testAsset;
        System.debug('기존 테스트 Asset 삭제 완료');
        
        // 서비스로 Asset 생성
        Asset serviceAsset = OrderAssetCreationService.createAssetFromCompletedOrder(testOrder.Id);
        
        if (serviceAsset != null) {
            System.debug('✅ OrderAssetCreationService로 Asset 생성 성공!');
            System.debug('- Asset ID: ' + serviceAsset.Id);
            System.debug('- Asset Name: ' + serviceAsset.Name);
        } else {
            System.debug('⚠️ OrderAssetCreationService에서 Asset이 생성되지 않았습니다.');
        }
        
    } catch (Exception e) {
        System.debug('❌ Asset 생성 오류: ' + e.getMessage());
        System.debug('Stack Trace: ' + e.getStackTraceString());
    }
}

System.debug('=== Asset 수동 생성 테스트 완료 ===');

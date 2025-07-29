/**
 * Asset 자동 생성 시스템 테스트 스크립트
 * Order 완납 시 Asset 자동 생성 검증
 */

System.debug('=== Asset 자동 생성 시스템 테스트 시작 ===');

// 1. 테스트할 Order 확인
String targetOrderNumber = '00000158'; // 또는 다른 Order Number
List<Order> testOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount, Status
    FROM Order 
    WHERE OrderNumber = :targetOrderNumber
    LIMIT 1
];

if (testOrders.isEmpty()) {
    System.debug('ERROR: Order ' + targetOrderNumber + '를 찾을 수 없습니다.');
} else {
    Order testOrder = testOrders[0];
    System.debug('테스트 Order 정보:');
    System.debug('- Order ID: ' + testOrder.Id);
    System.debug('- Order Number: ' + testOrder.OrderNumber);
    System.debug('- 고객: ' + testOrder.Account.Name);
    System.debug('- 총 금액: ' + (testOrder.TotalAmount != null ? testOrder.TotalAmount.format() : '0') + '원');
    System.debug('- 상태: ' + testOrder.Status);
    
    // 2. 현재 PaymentStatus 확인
    List<PaymentStatus__c> paymentStatuses = [
        SELECT Id, InstallmentNumber__c, Amount__c, Status__c, DueDate__c
        FROM PaymentStatus__c 
        WHERE Order__c = :testOrder.Id
        ORDER BY InstallmentNumber__c
    ];
    
    System.debug('\n현재 PaymentStatus 상태:');
    if (paymentStatuses.isEmpty()) {
        System.debug('- PaymentStatus 레코드가 없습니다.');
    } else {
        for (PaymentStatus__c ps : paymentStatuses) {
            System.debug('- ' + ps.InstallmentNumber__c + '차: ' + 
                        (ps.Amount__c != null ? ps.Amount__c.format() : '0') + '원, ' +
                        '상태: ' + ps.Status__c + ', ' +
                        '예정일: ' + (ps.DueDate__c != null ? ps.DueDate__c.format() : '미정'));
        }
    }
    
    // 3. 완납 상태 확인
    Boolean isFullyPaid = OrderAssetCreationService.isOrderFullyPaid(testOrder.Id);
    System.debug('\n완납 상태: ' + (isFullyPaid ? '완납 완료' : '미완납'));
    
    // 4. 기존 Asset 확인
    List<Asset> existingAssets = [
        SELECT Id, Name, Status, PurchaseDate, Price
        FROM Asset 
        WHERE SerialNumber = :testOrder.OrderNumber
    ];
    
    System.debug('\n기존 Asset 상태:');
    if (existingAssets.isEmpty()) {
        System.debug('- 기존 Asset 없음');
    } else {
        for (Asset asset : existingAssets) {
            System.debug('- Asset ID: ' + asset.Id);
            System.debug('- Asset Name: ' + asset.Name);
            System.debug('- Status: ' + asset.Status);
            System.debug('- Purchase Date: ' + (asset.PurchaseDate != null ? asset.PurchaseDate.format() : '미정'));
            System.debug('- Price: ' + (asset.Price != null ? asset.Price.format() : '0') + '원');
        }
    }
    
    // 5. 모든 PaymentStatus를 완납으로 업데이트 (테스트용)
    if (!paymentStatuses.isEmpty() && !isFullyPaid) {
        System.debug('\n=== 테스트: 모든 PaymentStatus를 완납으로 업데이트 ===');
        
        List<PaymentStatus__c> toUpdate = new List<PaymentStatus__c>();
        for (PaymentStatus__c ps : paymentStatuses) {
            if (ps.Status__c != '완납') {
                ps.Status__c = '완납';
                toUpdate.add(ps);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
                System.debug('PaymentStatus 업데이트 완료: ' + toUpdate.size() + '개 레코드');
                
                // 잠시 대기 후 Asset 생성 확인
                System.debug('\n=== Asset 자동 생성 확인 ===');
                
                // 업데이트된 완납 상태 재확인
                Boolean newIsFullyPaid = OrderAssetCreationService.isOrderFullyPaid(testOrder.Id);
                System.debug('업데이트 후 완납 상태: ' + (newIsFullyPaid ? '완납 완료' : '미완납'));
                
                if (newIsFullyPaid) {
                    // Asset 생성 시도
                    try {
                        Asset newAsset = OrderAssetCreationService.createAssetFromCompletedOrder(testOrder.Id);
                        if (newAsset != null) {
                            System.debug('✅ Asset 자동 생성 성공!');
                            System.debug('- Asset ID: ' + newAsset.Id);
                            System.debug('- Asset Name: ' + newAsset.Name);
                            System.debug('- Serial Number: ' + newAsset.SerialNumber);
                            System.debug('- Status: ' + newAsset.Status);
                            System.debug('- Price: ' + (newAsset.Price != null ? newAsset.Price.format() : '0') + '원');
                        }
                    } catch (Exception e) {
                        System.debug('❌ Asset 생성 오류: ' + e.getMessage());
                    }
                } else {
                    System.debug('⚠️ PaymentStatus 업데이트 후에도 완납 상태가 아닙니다.');
                }
                
            } catch (Exception e) {
                System.debug('❌ PaymentStatus 업데이트 오류: ' + e.getMessage());
            }
        } else {
            System.debug('업데이트할 PaymentStatus가 없습니다.');
        }
    } else if (isFullyPaid) {
        System.debug('\n=== 이미 완납 상태 - Asset 생성 테스트 ===');
        try {
            Asset newAsset = OrderAssetCreationService.createAssetFromCompletedOrder(testOrder.Id);
            if (newAsset != null) {
                System.debug('✅ Asset 생성 완료!');
                System.debug('- Asset ID: ' + newAsset.Id);
                System.debug('- Asset Name: ' + newAsset.Name);
            }
        } catch (Exception e) {
            System.debug('Asset 생성 중 오류: ' + e.getMessage());
        }
    }
}

// 6. 전체 시스템 상태 요약
System.debug('\n=== Asset 자동 생성 시스템 상태 요약 ===');

// Asset 총 개수
Integer totalAssets = [SELECT COUNT() FROM Asset];
System.debug('전체 Asset 개수: ' + totalAssets);

// 최근 생성된 Asset (오늘)
List<Asset> todayAssets = [
    SELECT Id, Name, SerialNumber, CreatedDate
    FROM Asset 
    WHERE CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('오늘 생성된 Asset: ' + todayAssets.size() + '개');
for (Asset asset : todayAssets) {
    System.debug('- ' + asset.Name + ' (Order: ' + asset.SerialNumber + ')');
}

System.debug('\n=== Asset 자동 생성 시스템 테스트 완료 ===');

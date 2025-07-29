/**
 * 정제된 Asset 생성 테스트 - 실제 필드 구조 기반
 */

System.debug('=== 정제된 Asset 생성 테스트 시작 ===');

// 1. Order와 PaymentStatus 확인
List<Order> testOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount, Status,
           EffectiveDate, EndDate, Contact__c, Contact.Name, OwnerId, Owner.Name
    FROM Order 
    WHERE AccountId != null
    LIMIT 3
];

System.debug('테스트 가능한 Order 개수: ' + testOrders.size());

for (Order ord : testOrders) {
    System.debug('\n--- Order: ' + ord.OrderNumber + ' ---');
    System.debug('고객: ' + ord.Account.Name);
    System.debug('총 금액: ' + (ord.TotalAmount != null ? ord.TotalAmount.format() : '0') + '원');
    System.debug('시작일: ' + (ord.EffectiveDate != null ? ord.EffectiveDate.format() : '미설정'));
    System.debug('종료일: ' + (ord.EndDate != null ? ord.EndDate.format() : '무기한'));
    System.debug('연락처: ' + (ord.Contact.Name != null ? ord.Contact.Name : '미설정'));
    
    // PaymentStatus 확인
    List<PaymentStatus__c> payments = [
        SELECT Id, InstallmentNumber__c, Amount__c, Status__c, DueDate__c, PaidDate__c
        FROM PaymentStatus__c 
        WHERE Order__c = :ord.Id
        ORDER BY InstallmentNumber__c
    ];
    
    System.debug('PaymentStatus 개수: ' + payments.size());
    
    if (!payments.isEmpty()) {
        Integer totalPayments = payments.size();
        Integer completedPayments = 0;
        
        for (PaymentStatus__c ps : payments) {
            System.debug('  ' + ps.InstallmentNumber__c + '차: ' + 
                        (ps.Amount__c != null ? ps.Amount__c.format() : '0') + '원, ' +
                        '상태: ' + ps.Status__c + 
                        (ps.PaidDate__c != null ? ', 납부일: ' + ps.PaidDate__c.format() : ''));
            
            if (ps.Status__c == '완납') {
                completedPayments++;
            }
        }
        
        Boolean isFullyPaid = (totalPayments > 0 && totalPayments == completedPayments);
        System.debug('완납 상태: ' + isFullyPaid + ' (' + completedPayments + '/' + totalPayments + ')');
        
        // 완납 확인 서비스 테스트
        Boolean serviceCheck = OrderAssetCreationService.isOrderFullyPaid(ord.Id);
        System.debug('서비스 완납 확인: ' + serviceCheck);
        
        if (isFullyPaid) {
            System.debug('🎯 완납 Order 발견! Asset 생성 테스트 시작...');
            
            try {
                // 기존 Asset 확인
                List<Asset> existingAssets = [
                    SELECT Id, Name FROM Asset 
                    WHERE SerialNumber = :ord.OrderNumber
                ];
                
                if (!existingAssets.isEmpty()) {
                    System.debug('⚠️ 이미 Asset이 존재합니다: ' + existingAssets[0].Name);
                } else {
                    // Asset 생성 테스트
                    Asset newAsset = OrderAssetCreationService.createAssetFromCompletedOrder(ord.Id);
                    
                    if (newAsset != null) {
                        System.debug('✅ Asset 생성 성공!');
                        System.debug('- Asset ID: ' + newAsset.Id);
                        System.debug('- Asset Name: ' + newAsset.Name);
                        System.debug('- Serial Number: ' + newAsset.SerialNumber);
                        System.debug('- Contact: ' + (newAsset.ContactId != null ? 'Connected' : 'Not Connected'));
                        System.debug('- Purchase Date: ' + (newAsset.PurchaseDate != null ? newAsset.PurchaseDate.format() : 'Not Set'));
                        System.debug('- Lifecycle End: ' + (newAsset.LifecycleEndDate != null ? newAsset.LifecycleEndDate.format() : 'Not Set'));
                        
                        // 생성된 Asset 상세 조회
                        Asset createdAssetDetail = [
                            SELECT Id, Name, SerialNumber, AccountId, Account.Name,
                                   ContactId, Contact.Name, PurchaseDate, InstallDate,
                                   LifecycleEndDate, Status, Price, Description
                            FROM Asset 
                            WHERE Id = :newAsset.Id
                        ];
                        
                        System.debug('\n--- 생성된 Asset 상세 정보 ---');
                        System.debug('고객: ' + createdAssetDetail.Account.Name);
                        System.debug('연락처: ' + (createdAssetDetail.Contact?.Name ?? '없음'));
                        System.debug('구매일: ' + (createdAssetDetail.PurchaseDate?.format() ?? '없음'));
                        System.debug('설치일: ' + (createdAssetDetail.InstallDate?.format() ?? '없음'));
                        System.debug('종료일: ' + (createdAssetDetail.LifecycleEndDate?.format() ?? '없음'));
                        System.debug('가격: ' + (createdAssetDetail.Price?.format() ?? '0') + '원');
                        System.debug('상태: ' + createdAssetDetail.Status);
                        
                        break; // 첫 번째 성공 후 종료
                    }
                }
                
            } catch (Exception e) {
                System.debug('❌ Asset 생성 오류: ' + e.getMessage());
                System.debug('Stack Trace: ' + e.getStackTraceString());
            }
        }
    } else {
        System.debug('PaymentStatus가 없습니다.');
    }
}

// 전체 Asset 현황 확인
System.debug('\n=== Asset 현황 ===');
Integer totalAssets = [SELECT COUNT() FROM Asset];
System.debug('전체 Asset 개수: ' + totalAssets);

if (totalAssets > 0) {
    List<Asset> recentAssets = [
        SELECT Id, Name, SerialNumber, Account.Name, CreatedDate, Status
        FROM Asset 
        ORDER BY CreatedDate DESC 
        LIMIT 3
    ];
    
    System.debug('최근 Asset:');
    for (Asset asset : recentAssets) {
        System.debug('- ' + asset.Name + ' (' + asset.Account.Name + ') - ' + asset.Status);
    }
}

System.debug('\n=== 정제된 Asset 생성 테스트 완료 ===');

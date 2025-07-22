/**
 * OrderAssetNavigator 컴포넌트 테스트
 * Order에서 Asset으로의 네비게이션 기능 테스트
 */

System.debug('=== OrderAssetNavigator 컴포넌트 테스트 ===');

// 1. 테스트용 Order 선택
List<Order> testOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount
    FROM Order 
    WHERE AccountId != null
    ORDER BY CreatedDate DESC
    LIMIT 3
];

if (testOrders.isEmpty()) {
    System.debug('테스트용 Order가 없습니다.');
    return;
}

for (Order ord : testOrders) {
    System.debug('\n--- Order: ' + ord.OrderNumber + ' (' + ord.Account.Name + ') ---');
    
    try {
        // OrderAssetNavigatorController 테스트
        OrderAssetNavigatorController.OrderAssetInfo assetInfo = 
            OrderAssetNavigatorController.getOrderAssetInfo(ord.Id);
        
        System.debug('📊 납부 요약:');
        System.debug('  - 총 납부 회차: ' + assetInfo.paymentSummary.totalPayments);
        System.debug('  - 완료된 회차: ' + assetInfo.paymentSummary.completedPayments);
        System.debug('  - 남은 회차: ' + assetInfo.paymentSummary.remainingPayments);
        System.debug('  - 완납 여부: ' + assetInfo.paymentSummary.isFullyPaid);
        System.debug('  - 총 금액: ' + assetInfo.paymentSummary.totalAmount);
        
        if (assetInfo.assetInfo != null) {
            System.debug('✅ 연결된 Asset:');
            System.debug('  - Asset ID: ' + assetInfo.assetInfo.Id);
            System.debug('  - Asset 이름: ' + assetInfo.assetInfo.Name);
            System.debug('  - Serial Number: ' + assetInfo.assetInfo.SerialNumber);
            System.debug('  - 상태: ' + assetInfo.assetInfo.Status);
            System.debug('  - 구매일: ' + assetInfo.assetInfo.PurchaseDate);
            System.debug('  - 설치일: ' + assetInfo.assetInfo.InstallDate);
        } else {
            System.debug('❌ 연결된 Asset 없음');
            
            // 완납된 경우 Asset 생성 테스트
            if (assetInfo.paymentSummary.isFullyPaid) {
                System.debug('🔄 완납 상태 - Asset 생성 테스트 진행');
                
                try {
                    OrderAssetNavigatorController.AssetCreationResult createResult = 
                        OrderAssetNavigatorController.createAssetFromOrder(ord.Id);
                    
                    if (createResult.success) {
                        System.debug('✅ Asset 생성 성공: ' + createResult.assetId);
                        System.debug('   메시지: ' + createResult.message);
                    } else {
                        System.debug('❌ Asset 생성 실패: ' + createResult.message);
                    }
                } catch (Exception createError) {
                    System.debug('❌ Asset 생성 오류: ' + createError.getMessage());
                }
            } else {
                System.debug('⏳ 납부 미완료 - Asset 생성 불가');
            }
        }
        
    } catch (Exception e) {
        System.debug('❌ 테스트 오류: ' + e.getMessage());
    }
}

System.debug('\n=== 컴포넌트 사용 가이드 ===');
System.debug('1. Order 레코드 페이지에 OrderAssetNavigator 컴포넌트 추가');
System.debug('2. 컴포넌트가 납부 진행률과 Asset 연결 상태를 자동 표시');
System.debug('3. 완납 시 Asset 생성 버튼 또는 Asset 보기 버튼 제공');
System.debug('4. Asset으로 원클릭 네비게이션 가능');

System.debug('\n=== 기능 요약 ===');
System.debug('📈 납부 진행률 시각화');
System.debug('🔗 Order-Asset 연결 상태 표시');
System.debug('🚀 Asset으로 원클릭 네비게이션');
System.debug('🛠️ 완납 시 수동 Asset 생성');
System.debug('📱 반응형 UI 디자인');
System.debug('🔄 실시간 데이터 새로고침');

System.debug('\n✅ OrderAssetNavigator 컴포넌트 테스트 완료!');

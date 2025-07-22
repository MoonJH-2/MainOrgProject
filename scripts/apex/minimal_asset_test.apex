/**
 * 최소한의 Asset 생성 테스트
 */

System.debug('=== 최소한의 Asset 생성 테스트 ===');

// 직접 Asset 생성 테스트
try {
    // 첫 번째 Account 가져오기
    List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
    
    if (accounts.isEmpty()) {
        System.debug('❌ 테스트할 Account가 없습니다.');
    } else {
        Account testAccount = accounts[0];
        
        // Asset 직접 생성
        Asset newAsset = new Asset();
        newAsset.Name = testAccount.Name + ' - 테스트 Asset';
        newAsset.AccountId = testAccount.Id;
        newAsset.SerialNumber = 'TEST-' + DateTime.now().getTime();
        newAsset.PurchaseDate = Date.today();
        newAsset.InstallDate = Date.today();
        newAsset.Status = 'Purchased';
        newAsset.Price = 1000000;
        newAsset.Quantity = 1;
        newAsset.Description = '테스트용 Asset - ' + DateTime.now().format();
        
        insert newAsset;
        
        System.debug('✅ Asset 생성 성공!');
        System.debug('- Asset ID: ' + newAsset.Id);
        System.debug('- Asset Name: ' + newAsset.Name);
        System.debug('- Serial Number: ' + newAsset.SerialNumber);
        System.debug('- Account: ' + testAccount.Name);
        
        // 전체 Asset 개수 확인
        Integer totalAssets = [SELECT COUNT() FROM Asset];
        System.debug('전체 Asset 개수: ' + totalAssets);
        
    }
    
} catch (Exception e) {
    System.debug('❌ Asset 생성 오류: ' + e.getMessage());
}

System.debug('=== 테스트 완료 ===');

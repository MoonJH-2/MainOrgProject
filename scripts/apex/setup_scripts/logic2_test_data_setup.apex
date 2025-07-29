/**
 * Logic 2 원클릭 갱신 워크플로우 테스트
 * 목적: 5초 갱신 프로세스가 정상적으로 작동하는지 검증
 */

// 테스트 자산 데이터 생성
List<Asset> testAssets = new List<Asset>();
Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

Asset testAsset1 = new Asset(
    Name = 'Logic2테스트자산001',
    AccountId = testAccount.Id,
    Status = 'Installed',
    InstallDate = Date.today().addMonths(-12),
    UsageEndDate = Date.today().addDays(30), // 30일 후 만료 - 갱신 필요
    Price = 100000,
    Quantity = 1,
    계약상태__c = 'Active',
    우선순위점수__c = 85.0 // Logic 1에서 계산된 높은 우선순위
);

Asset testAsset2 = new Asset(
    Name = 'Logic2테스트자산002',
    AccountId = testAccount.Id,
    Status = 'Installed',
    InstallDate = Date.today().addMonths(-24),
    UsageEndDate = Date.today().addDays(15), // 15일 후 만료 - 긴급 갱신
    Price = 250000,
    Quantity = 2,
    계약상태__c = 'Active',
    우선순위점수__c = 92.5 // Logic 1에서 계산된 매우 높은 우선순위
);

testAssets.add(testAsset1);
testAssets.add(testAsset2);

try {
    insert testAssets;
    System.debug('Logic 2 테스트 자산 생성 완료: ' + testAssets.size() + '개');
    
    // 각 자산별 정보 출력
    for(Asset asset : testAssets) {
        System.debug('생성된 자산: ' + asset.Name + 
                    ', 만료일: ' + asset.UsageEndDate + 
                    ', 우선순위: ' + asset.우선순위점수__c);
    }
    
} catch(Exception e) {
    System.debug('테스트 자산 생성 실패: ' + e.getMessage());
}

System.debug('=== Logic 2 테스트 자산 생성 완료 ===');
System.debug('다음 단계: OneClickRenewalService.startRenewalProcess() 메소드 테스트 실행');

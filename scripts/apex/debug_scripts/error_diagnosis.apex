/**
 * 오류 진단 및 디버깅 스크립트
 * 목적: "Argument cannot be null" 오류의 정확한 원인 파악
 */

System.debug('🔍 === 오류 진단 시작 ===');

try {
    // 1. 생성된 데이터 확인
    List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = '테스트기업'];
    System.debug('✅ Account 데이터: ' + accounts.size() + '개');
    
    List<Asset> assets = [SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status FROM Asset WHERE Account.Name = '테스트기업'];
    System.debug('✅ Asset 데이터: ' + assets.size() + '개');
    
    if(!assets.isEmpty()) {
        Asset testAsset = assets[0];
        System.debug('Asset 상세:');
        System.debug('  - Name: ' + testAsset.Name);
        System.debug('  - AccountId: ' + testAsset.AccountId);
        System.debug('  - Account.Name: ' + testAsset.Account?.Name);
        System.debug('  - Price: ' + testAsset.Price);
        System.debug('  - InstallDate: ' + testAsset.InstallDate);
        System.debug('  - UsageEndDate: ' + testAsset.UsageEndDate);
        System.debug('  - Status: ' + testAsset.Status);
    }
    
    List<Opportunity> opportunities = [SELECT Id, Name, AccountId, StageName, CloseDate, Amount, Type FROM Opportunity WHERE Account.Name = '테스트기업'];
    System.debug('✅ Opportunity 데이터: ' + opportunities.size() + '개');
    
    // 2. 성과 추적 로직에서 사용하는 쿼리 테스트
    System.debug('');
    System.debug('🔍 === 성과 추적 로직 테스트 ===');
    
    // 오늘의 예상 매출 계산 테스트
    List<Asset> todayAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
        FROM Asset 
        WHERE Status = 'Installed' 
        AND InstallDate != null
        AND UsageEndDate != null
        AND InstallDate <= :Date.today().addDays(-300)
        ORDER BY Price DESC
    ];
    System.debug('오늘 예상 매출용 Asset: ' + todayAssets.size() + '개');
    
    // 월간 갱신 현황 테스트
    Date thisMonthStart = Date.today().toStartOfMonth();
    List<Opportunity> completedOpps = [
        SELECT Id, Name, Amount, CloseDate, StageName, Type
        FROM Opportunity 
        WHERE Type = 'Renewal'
        AND StageName = 'Closed Won'
        AND CloseDate >= :thisMonthStart
        AND CloseDate <= :Date.today()
    ];
    System.debug('이번 달 완료된 갱신: ' + completedOpps.size() + '개');
    
    List<Opportunity> inProgressOpps = [
        SELECT Id, Name, Amount, CloseDate, StageName, Type
        FROM Opportunity 
        WHERE Type = 'Renewal'
        AND StageName != 'Closed Won'
        AND StageName != 'Closed Lost'
        AND CloseDate >= :Date.today()
    ];
    System.debug('진행 중인 갱신: ' + inProgressOpps.size() + '개');
    
    // 3. Null 값 검증 (오류 원인 가능성)
    System.debug('');
    System.debug('🔍 === Null 값 검증 ===');
    
    for(Asset a : todayAssets) {
        if(a.AccountId == null) System.debug('❌ Asset AccountId가 null: ' + a.Name);
        if(a.Account?.Name == null) System.debug('❌ Account Name이 null: ' + a.Name);
        if(a.Price == null) System.debug('❌ Asset Price가 null: ' + a.Name);
        if(a.InstallDate == null) System.debug('❌ InstallDate가 null: ' + a.Name);
        if(a.UsageEndDate == null) System.debug('❌ UsageEndDate가 null: ' + a.Name);
    }
    
    // 4. 원클릭 갱신 로직 테스트 (300일 이상 경과 조건)
    System.debug('');
    System.debug('🔍 === 원클릭 갱신 조건 테스트 ===');
    
    List<Asset> renewalAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
        FROM Asset 
        WHERE Status = 'Installed'
        AND InstallDate <= :Date.today().addDays(-300)
        AND UsageEndDate >= :Date.today()
    ];
    System.debug('갱신 가능한 Asset: ' + renewalAssets.size() + '개');
    
    for(Asset a : renewalAssets) {
        Integer daysSinceInstall = Date.today().daysBetween(a.InstallDate);
        Integer daysUntilExpiry = Date.today().daysBetween(a.UsageEndDate);
        System.debug('Asset: ' + a.Name + ' | 설치 후: ' + daysSinceInstall + '일 | 만료까지: ' + daysUntilExpiry + '일');
    }
    
    // 5. 사용자 권한 확인
    System.debug('');
    System.debug('🔍 === 사용자 권한 확인 ===');
    System.debug('현재 사용자: ' + UserInfo.getName());
    System.debug('Profile: ' + [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name);
    System.debug('Asset 접근: ' + Schema.sObjectType.Asset.isAccessible());
    System.debug('Opportunity 접근: ' + Schema.sObjectType.Opportunity.isAccessible());
    System.debug('Account 접근: ' + Schema.sObjectType.Account.isAccessible());
    
} catch(Exception e) {
    System.debug('❌ 진단 중 오류 발생: ' + e.getMessage());
    System.debug('❌ 오류 타입: ' + e.getTypeName());
    System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
    System.debug('❌ 라인 번호: ' + e.getLineNumber());
}

System.debug('🔍 === 오류 진단 완료 ===');

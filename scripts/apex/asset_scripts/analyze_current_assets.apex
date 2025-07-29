/**
 * 현재 Asset 상태 분석 및 300일 조건 확인
 * 목적: 왜 대시보드에 데이터가 표시되지 않는지 원인 파악
 */

System.debug('🔍 === Asset 상태 분석 시작 ===');

try {
    // 1. 현재 생성된 모든 Asset 확인
    List<Asset> allAssets = [
        SELECT Id, Name, AccountId, Account.Name, Status, Price, InstallDate, UsageEndDate, 
               CreatedDate, LastModifiedDate
        FROM Asset 
        WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('📊 총 Asset 수: ' + allAssets.size());
    
    for(Asset a : allAssets) {
        Integer daysSinceInstall = a.InstallDate != null ? a.InstallDate.daysBetween(Date.today()) : 0;
        Integer daysUntilExpiry = a.UsageEndDate != null ? Date.today().daysBetween(a.UsageEndDate) : 0;
        
        System.debug('Asset: ' + a.Name);
        System.debug('  - Account: ' + a.Account?.Name);
        System.debug('  - Status: ' + a.Status);
        System.debug('  - Price: ' + a.Price);
        System.debug('  - InstallDate: ' + a.InstallDate);
        System.debug('  - UsageEndDate: ' + a.UsageEndDate);
        System.debug('  - 설치 후 경과일: ' + daysSinceInstall + '일');
        System.debug('  - 만료까지: ' + daysUntilExpiry + '일');
        System.debug('  - 300일 이상?: ' + (daysSinceInstall >= 300));
        System.debug('');
    }
    
    // 2. 우선순위 계산 로직 테스트 (현재 조건)
    System.debug('🔍 현재 우선순위 로직 테스트 (300일 조건)');
    List<Asset> currentPriorityAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
        FROM Asset 
        WHERE Status = 'Installed' 
        AND InstallDate != null
        AND UsageEndDate != null
        AND InstallDate <= :Date.today().addDays(-300)  // 300일 조건
        ORDER BY Price DESC
    ];
    System.debug('300일 조건 Asset 수: ' + currentPriorityAssets.size());
    
    // 3. 원클릭 갱신 로직 테스트 (현재 조건)
    System.debug('🔍 현재 원클릭 갱신 로직 테스트 (300일 조건)');
    List<Asset> currentRenewalAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
        FROM Asset 
        WHERE Status = 'Installed'
        AND InstallDate <= :Date.today().addDays(-300)  // 300일 조건
        AND UsageEndDate >= :Date.today()
    ];
    System.debug('300일 조건 갱신 가능 Asset 수: ' + currentRenewalAssets.size());
    
    // 4. 새로운 조건 테스트 (1일 조건)
    System.debug('🔍 새로운 우선순위 로직 테스트 (1일 조건)');
    List<Asset> newPriorityAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
        FROM Asset 
        WHERE Status = 'Installed' 
        AND InstallDate != null
        AND UsageEndDate != null
        AND InstallDate <= :Date.today().addDays(-1)  // 1일 조건으로 변경
        ORDER BY Price DESC
    ];
    System.debug('1일 조건 Asset 수: ' + newPriorityAssets.size());
    
    // 5. 새로운 원클릭 갱신 로직 테스트 (1일 조건)
    System.debug('🔍 새로운 원클릭 갱신 로직 테스트 (1일 조건)');
    List<Asset> newRenewalAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
        FROM Asset 
        WHERE Status = 'Installed'
        AND InstallDate <= :Date.today().addDays(-1)  // 1일 조건으로 변경
        AND UsageEndDate >= :Date.today()
    ];
    System.debug('1일 조건 갱신 가능 Asset 수: ' + newRenewalAssets.size());
    
    // 6. 관련 Opportunity 확인
    System.debug('🔍 관련 Opportunity 확인');
    List<Opportunity> relatedOpps = [
        SELECT Id, Name, AccountId, Account.Name, StageName, CloseDate, Amount, Type, CreatedDate
        FROM Opportunity 
        WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'
        ORDER BY CreatedDate DESC
    ];
    System.debug('관련 Opportunity 수: ' + relatedOpps.size());
    
    for(Opportunity opp : relatedOpps) {
        System.debug('Opportunity: ' + opp.Name);
        System.debug('  - Account: ' + opp.Account?.Name);
        System.debug('  - Stage: ' + opp.StageName);
        System.debug('  - Amount: ' + opp.Amount);
        System.debug('  - Type: ' + opp.Type);
        System.debug('  - CloseDate: ' + opp.CloseDate);
        System.debug('');
    }
    
} catch(Exception e) {
    System.debug('❌ 분석 중 오류: ' + e.getMessage());
    System.debug('❌ 스택: ' + e.getStackTraceString());
}

System.debug('🔍 === Asset 상태 분석 완료 ===');

/**
 * 완전히 안전한 테스트 데이터 생성 (국가/주 필드 오류 해결)
 * 목적: 모든 환경에서 동작하는 안전한 데이터 생성
 */

System.debug('🛡️ === 안전한 테스트 데이터 생성 시작 ===');

try {
    // 1. 기존 데이터 완전 정리
    System.debug('🗑️ 모든 기존 테스트 데이터 정리...');
    
    // Opportunity 먼저 삭제 (외래키 참조 때문)
    List<Opportunity> allOpps = [SELECT Id FROM Opportunity WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    if(!allOpps.isEmpty()) {
        delete allOpps;
        System.debug('✅ 모든 Opportunity 삭제: ' + allOpps.size() + '개');
    }
    
    // Case 삭제
    List<Case> allCases = [SELECT Id FROM Case WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    if(!allCases.isEmpty()) {
        delete allCases;
        System.debug('✅ 모든 Case 삭제: ' + allCases.size() + '개');
    }
    
    // Asset 삭제
    List<Asset> allAssets = [SELECT Id FROM Asset WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    if(!allAssets.isEmpty()) {
        delete allAssets;
        System.debug('✅ 모든 Asset 삭제: ' + allAssets.size() + '개');
    }
    
    // Account 마지막 삭제
    List<Account> allAccounts = [SELECT Id FROM Account WHERE Name LIKE '%테스트%' OR Name LIKE '%우수%' OR Name LIKE '%주의%'];
    if(!allAccounts.isEmpty()) {
        delete allAccounts;
        System.debug('✅ 모든 Account 삭제: ' + allAccounts.size() + '개');
    }
    
    // 2. 최소한의 필수 필드만으로 안전한 Account 생성
    System.debug('🚀 안전한 Account 생성...');
    
    Account safeAccount1 = new Account(
        Name = '테스트기업',
        Type = 'Customer'
    );
    
    Account safeAccount2 = new Account(
        Name = '우수기업', 
        Type = 'Customer'
    );
    
    Account safeAccount3 = new Account(
        Name = '주의기업',
        Type = 'Customer'
    );
    
    List<Account> accountsToInsert = new List<Account>{safeAccount1, safeAccount2, safeAccount3};
    insert accountsToInsert;
    System.debug('✅ 안전한 Account 3개 생성 완료');
    
    // 3. 안전한 Asset 생성 (필수 필드만)
    System.debug('🚀 안전한 Asset 생성...');
    
    Asset urgentAsset = new Asset(
        Name = '긴급 갱신 시스템',
        AccountId = safeAccount1.Id,
        Status = 'Installed',
        Price = 30000000,
        InstallDate = Date.today().addDays(-350), // 350일 전 설치
        UsageEndDate = Date.today().addDays(5) // 5일 후 만료 - 긴급!
    );
    
    Asset mediumAsset = new Asset(
        Name = '표준 업무 시스템', 
        AccountId = safeAccount2.Id,
        Status = 'Installed',
        Price = 15000000,
        InstallDate = Date.today().addDays(-320), // 320일 전 설치
        UsageEndDate = Date.today().addDays(45) // 45일 후 만료 - 중간
    );
    
    List<Asset> assetsToInsert = new List<Asset>{urgentAsset, mediumAsset};
    insert assetsToInsert;
    System.debug('✅ 안전한 Asset 2개 생성 완료');
    
    // 4. 안전한 Opportunity 생성
    System.debug('🚀 안전한 Opportunity 생성...');
    
    Opportunity completedOpp = new Opportunity(
        Name = '완료된 갱신 - 테스트기업',
        AccountId = safeAccount1.Id,
        StageName = 'Closed Won',
        CloseDate = Date.today().addDays(-5), // 5일 전 완료
        Amount = 25000000,
        Type = 'Renewal'
    );
    
    Opportunity inProgressOpp = new Opportunity(
        Name = '진행중인 갱신 - 우수기업',
        AccountId = safeAccount2.Id,
        StageName = 'Prospecting', 
        CloseDate = Date.today().addDays(30), // 30일 후 예정
        Amount = 40000000,
        Type = 'Renewal'
    );
    
    List<Opportunity> oppsToInsert = new List<Opportunity>{completedOpp, inProgressOpp};
    insert oppsToInsert;
    System.debug('✅ 안전한 Opportunity 2개 생성 완료');
    
    // 5. 고객 건강도를 위한 Case 생성
    System.debug('🚀 건강도 분석용 Case 생성...');
    
    Case riskCase1 = new Case(
        AccountId = safeAccount3.Id, // 주의기업
        Subject = '시스템 오류 보고',
        Status = 'New',
        Priority = 'High'
    );
    
    Case riskCase2 = new Case(
        AccountId = safeAccount3.Id, // 주의기업 (같은 고객에 2개 Case = 위험)
        Subject = '성능 저하 문의',
        Status = 'Working',
        Priority = 'Medium'
    );
    
    List<Case> casesToInsert = new List<Case>{riskCase1, riskCase2};
    insert casesToInsert;
    System.debug('✅ 건강도 분석용 Case 2개 생성 완료');
    
    // 6. 최종 검증
    System.debug('');
    System.debug('📊 === 최종 데이터 검증 ===');
    
    Integer finalAccountCount = [SELECT COUNT() FROM Account WHERE Name LIKE '%테스트%' OR Name LIKE '%우수%' OR Name LIKE '%주의%'];
    Integer finalAssetCount = [SELECT COUNT() FROM Asset WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    Integer finalOppCount = [SELECT COUNT() FROM Opportunity WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    Integer finalCaseCount = [SELECT COUNT() FROM Case WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    
    System.debug('✅ 최종 Account: ' + finalAccountCount + '개');
    System.debug('✅ 최종 Asset: ' + finalAssetCount + '개');
    System.debug('✅ 최종 Opportunity: ' + finalOppCount + '개');
    System.debug('✅ 최종 Case: ' + finalCaseCount + '개');
    
} catch(Exception e) {
    System.debug('❌ 안전한 생성 중 오류: ' + e.getMessage());
    System.debug('❌ 타입: ' + e.getTypeName());
    System.debug('❌ 라인: ' + e.getLineNumber());
    System.debug('❌ 스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('🎯 === 예상 대시보드 결과 ===');
System.debug('💰 오늘 예상 매출: 4,050만원');
System.debug('  🔥 테스트기업 긴급: 2,700만원 (3,000만원 × 90%)');
System.debug('  ⚠️ 우수기업 중간: 1,350만원 (1,500만원 × 90%)');
System.debug('🎯 월간 완료: 1건, 2,500만원');
System.debug('🎯 월간 진행: 1건, 4,000만원');
System.debug('🏥 고객 건강도:');
System.debug('  🟢 건강: 2명 (테스트기업, 우수기업)');
System.debug('  🔴 위험: 1명 (주의기업 - Case 2건)');
System.debug('🏆 실버 레벨 달성!');
System.debug('');
System.debug('🛡️ === 안전한 데이터 생성 완료 ===');
System.debug('💡 이제 Assets Performance 대시보드를 새로고침하세요!');

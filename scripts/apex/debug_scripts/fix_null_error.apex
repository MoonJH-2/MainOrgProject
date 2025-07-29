/**
 * 오류 해결을 위한 데이터 정리 및 재생성
 * 목적: Null 값 문제 해결 및 완전한 데이터 생성
 */

System.debug('🔧 === 오류 해결 시작 ===');

try {
    // 1. 기존 불완전한 데이터 삭제
    System.debug('🗑️ 기존 테스트 데이터 정리 중...');
    
    List<Opportunity> oldOpps = [SELECT Id FROM Opportunity WHERE Account.Name = '테스트기업'];
    if(!oldOpps.isEmpty()) {
        delete oldOpps;
        System.debug('✅ 기존 Opportunity 삭제: ' + oldOpps.size() + '개');
    }
    
    List<Asset> oldAssets = [SELECT Id FROM Asset WHERE Account.Name = '테스트기업'];
    if(!oldAssets.isEmpty()) {
        delete oldAssets;
        System.debug('✅ 기존 Asset 삭제: ' + oldAssets.size() + '개');
    }
    
    List<Account> oldAccounts = [SELECT Id FROM Account WHERE Name = '테스트기업'];
    if(!oldAccounts.isEmpty()) {
        delete oldAccounts;
        System.debug('✅ 기존 Account 삭제: ' + oldAccounts.size() + '개');
    }
    
    // 2. 완전한 데이터로 재생성
    System.debug('🚀 완전한 테스트 데이터 재생성...');
    
    // Account 생성 (필수 필드 모두 포함, 국가 오류 수정)
    Account newAccount = new Account(
        Name = '테스트기업',
        Type = 'Customer',
        Industry = 'Technology',
        Phone = '02-1234-5678',
        BillingStreet = '서울특별시 강남구 테헤란로 123',
        BillingCity = '서울',
        BillingPostalCode = '06142'
        // BillingCountry와 BillingState 제거 (State/Country Picklist 오류 방지)
    );
    insert newAccount;
    System.debug('✅ 완전한 Account 생성: ' + newAccount.Name);
    
    // Asset 생성 (모든 필수 필드 + 추가 안전장치)
    Asset safeAsset = new Asset(
        Name = '긴급 갱신 시스템',
        AccountId = newAccount.Id,
        Status = 'Installed',
        Price = 30000000.00, // 명시적 Decimal
        Quantity = 1,
        InstallDate = Date.today().addDays(-350), // 350일 전
        UsageEndDate = Date.today().addDays(5), // 5일 후 만료
        PurchaseDate = Date.today().addDays(-350),
        Description = '긴급 갱신이 필요한 핵심 시스템',
        SerialNumber = 'TEST-2024-001',
        Product2Id = null // Product가 없어도 Asset 생성 가능
    );
    insert safeAsset;
    System.debug('✅ 완전한 Asset 생성: ' + safeAsset.Name);
    
    // Asset 검증
    Asset verifyAsset = [SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status, Quantity FROM Asset WHERE Id = :safeAsset.Id];
    System.debug('검증 - Account.Name: ' + verifyAsset.Account.Name);
    System.debug('검증 - Price: ' + verifyAsset.Price);
    System.debug('검증 - InstallDate: ' + verifyAsset.InstallDate);
    System.debug('검증 - UsageEndDate: ' + verifyAsset.UsageEndDate);
    
    // 완료된 Opportunity 생성 (이번 달)
    Opportunity completedOpp = new Opportunity(
        Name = '테스트기업 - 시스템 갱신 완료',
        AccountId = newAccount.Id,
        StageName = 'Closed Won',
        CloseDate = Date.today().addDays(-7), // 7일 전 완료
        Amount = 25000000.00, // 명시적 Decimal
        Type = 'Renewal',
        Probability = 100,
        Description = '성공적으로 완료된 갱신 계약',
        LeadSource = 'Existing Customer'
    );
    insert completedOpp;
    System.debug('✅ 완료된 Opportunity 생성: ' + completedOpp.Amount);
    
    // 진행 중인 Opportunity 생성
    Opportunity inProgressOpp = new Opportunity(
        Name = '테스트기업 - 확장 솔루션 갱신',
        AccountId = newAccount.Id,
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30), // 30일 후 예정
        Amount = 40000000.00, // 명시적 Decimal
        Type = 'Renewal',
        Probability = 75,
        Description = '진행 중인 갱신 프로세스',
        LeadSource = 'Existing Customer'
    );
    insert inProgressOpp;
    System.debug('✅ 진행 중인 Opportunity 생성: ' + inProgressOpp.Amount);
    
    // 3. 추가 안전 데이터 생성 (다양한 시나리오)
    System.debug('🛡️ 추가 안전 데이터 생성...');
    
    // 두 번째 Account (건강한 고객, 국가 필드 제거)
    Account healthyAccount = new Account(
        Name = '우수기업',
        Type = 'Customer',
        Industry = 'Finance',
        Phone = '02-9876-5432',
        BillingCity = '서울'
        // BillingState 제거
    );
    insert healthyAccount;
    
    // 두 번째 Asset (중간 우선순위)
    Asset mediumAsset = new Asset(
        Name = '표준 업무 시스템',
        AccountId = healthyAccount.Id,
        Status = 'Installed',
        Price = 15000000.00,
        Quantity = 1,
        InstallDate = Date.today().addDays(-320),
        UsageEndDate = Date.today().addDays(45),
        Description = '표준 업무 처리 시스템'
    );
    insert mediumAsset;
    
    // 세 번째 Account (위험 고객)
    Account riskyAccount = new Account(
        Name = '주의기업',
        Type = 'Customer',
        Industry = 'Manufacturing'
    );
    insert riskyAccount;
    
    // 위험 고객용 Case 생성
    Case riskCase = new Case(
        AccountId = riskyAccount.Id,
        Subject = '시스템 오류 보고',
        Status = 'New',
        Priority = 'High',
        Origin = 'Phone',
        Description = '긴급 기술 지원 필요'
    );
    insert riskCase;
    
    // 4. 최종 데이터 검증
    System.debug('');
    System.debug('📊 === 최종 데이터 검증 ===');
    
    Integer accountCount = [SELECT COUNT() FROM Account WHERE Name LIKE '%기업%'];
    Integer assetCount = [SELECT COUNT() FROM Asset WHERE Account.Name LIKE '%기업%'];
    Integer oppCount = [SELECT COUNT() FROM Opportunity WHERE Account.Name LIKE '%기업%'];
    Integer caseCount = [SELECT COUNT() FROM Case WHERE Account.Name LIKE '%기업%'];
    
    System.debug('✅ 총 Account: ' + accountCount + '개');
    System.debug('✅ 총 Asset: ' + assetCount + '개');
    System.debug('✅ 총 Opportunity: ' + oppCount + '개');
    System.debug('✅ 총 Case: ' + caseCount + '개');
    
    // 5. 예상 대시보드 결과
    System.debug('');
    System.debug('🎯 === 예상 대시보드 결과 ===');
    System.debug('💰 오늘 예상 매출: 4,050만원');
    System.debug('  - 테스트기업 긴급: 2,700만원 (3,000만원 × 90%)');
    System.debug('  - 우수기업 표준: 1,350만원 (1,500만원 × 90%)');
    System.debug('🎯 월간 완료: 1건, 2,500만원');
    System.debug('🎯 월간 진행: 1건, 4,000만원');
    System.debug('🏥 고객 건강도: 건강 2명, 위험 1명');
    System.debug('🏆 실버 레벨 달성 예정!');
    
} catch(Exception e) {
    System.debug('❌ 해결 과정 중 오류: ' + e.getMessage());
    System.debug('❌ 타입: ' + e.getTypeName());
    System.debug('❌ 라인: ' + e.getLineNumber());
}

System.debug('🔧 === 오류 해결 완료 ===');
System.debug('💡 이제 대시보드를 새로고침하세요!');

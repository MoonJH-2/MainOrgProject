/**
 * 즉시 테스트 가능한 Asset 데이터 생성 (1일 조건으로 변경)
 * 목적: 수정된 로직으로 즉시 갱신 가능한 Asset 생성
 */

System.debug('🚀 === 즉시 갱신 가능한 Asset 데이터 생성 시작 ===');

try {
    // 1. 기존 데이터 완전 정리 (안전한 순서)
    System.debug('🗑️ 기존 데이터 정리...');
    
    List<Task> oldTasks = [SELECT Id FROM Task WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    if(!oldTasks.isEmpty()) {
        delete oldTasks;
        System.debug('✅ Task 삭제: ' + oldTasks.size() + '개');
    }
    
    List<Opportunity> oldOpps = [SELECT Id FROM Opportunity WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    if(!oldOpps.isEmpty()) {
        delete oldOpps;
        System.debug('✅ Opportunity 삭제: ' + oldOpps.size() + '개');
    }
    
    List<Case> oldCases = [SELECT Id FROM Case WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    if(!oldCases.isEmpty()) {
        delete oldCases;
        System.debug('✅ Case 삭제: ' + oldCases.size() + '개');
    }
    
    List<Asset> oldAssets = [SELECT Id FROM Asset WHERE Account.Name LIKE '%테스트%' OR Account.Name LIKE '%우수%' OR Account.Name LIKE '%주의%'];
    if(!oldAssets.isEmpty()) {
        delete oldAssets;
        System.debug('✅ Asset 삭제: ' + oldAssets.size() + '개');
    }
    
    List<Account> oldAccounts = [SELECT Id FROM Account WHERE Name LIKE '%테스트%' OR Name LIKE '%우수%' OR Name LIKE '%주의%'];
    if(!oldAccounts.isEmpty()) {
        delete oldAccounts;
        System.debug('✅ Account 삭제: ' + oldAccounts.size() + '개');
    }
    
    // 2. 테스트용 Account 생성
    System.debug('🏢 테스트 Account 생성...');
    
    List<Account> testAccounts = new List<Account>{
        new Account(Name = '긴급고객', Type = 'Customer'),
        new Account(Name = '중요고객', Type = 'Customer'), 
        new Account(Name = '일반고객', Type = 'Customer'),
        new Account(Name = '위험고객', Type = 'Customer')
    };
    insert testAccounts;
    System.debug('✅ Account 생성: ' + testAccounts.size() + '개');
    
    // 3. 즉시 갱신 가능한 Asset 생성 (1일 조건)
    System.debug('💼 즉시 갱신 가능한 Asset 생성...');
    
    List<Asset> testAssets = new List<Asset>{
        // 긴급 고액 Asset (어제 설치 = 1일 경과)
        new Asset(
            Name = '긴급 ERP 시스템',
            AccountId = testAccounts[0].Id,
            Status = 'Installed',
            Price = 50000000, // 5천만원
            InstallDate = Date.today().addDays(-1), // 어제 설치
            UsageEndDate = Date.today().addDays(30) // 30일 후 만료
        ),
        
        // 중요 중액 Asset (2일 전 설치)
        new Asset(
            Name = 'CRM 플랫폼',
            AccountId = testAccounts[1].Id,
            Status = 'Installed',
            Price = 20000000, // 2천만원
            InstallDate = Date.today().addDays(-2), // 2일 전 설치
            UsageEndDate = Date.today().addDays(60) // 60일 후 만료
        ),
        
        // 일반 소액 Asset (3일 전 설치)
        new Asset(
            Name = '보안 솔루션',
            AccountId = testAccounts[2].Id,
            Status = 'Installed',
            Price = 8000000, // 8백만원
            InstallDate = Date.today().addDays(-3), // 3일 전 설치
            UsageEndDate = Date.today().addDays(90) // 90일 후 만료
        ),
        
        // 위험 고객 Asset (1주일 전 설치)
        new Asset(
            Name = '기본 업무 시스템',
            AccountId = testAccounts[3].Id,
            Status = 'Installed',
            Price = 5000000, // 5백만원
            InstallDate = Date.today().addDays(-7), // 1주일 전 설치
            UsageEndDate = Date.today().addDays(45) // 45일 후 만료
        )
    };
    insert testAssets;
    System.debug('✅ Asset 생성: ' + testAssets.size() + '개');
    
    // 4. 월간 성과용 Opportunity 생성
    System.debug('💰 성과 분석용 Opportunity 생성...');
    
    List<Opportunity> testOpps = new List<Opportunity>{
        // 완료된 갱신 (이번 달)
        new Opportunity(
            Name = '긴급고객 - 완료된 갱신',
            AccountId = testAccounts[0].Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-3),
            Amount = 30000000, // 3천만원
            Type = 'Renewal'
        ),
        
        // 진행 중인 갱신
        new Opportunity(
            Name = '중요고객 - 진행중 갱신',
            AccountId = testAccounts[1].Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            Amount = 25000000, // 2천500만원
            Type = 'Renewal'
        ),
        
        // 추가 완료된 갱신 (실버 레벨 달성용)
        new Opportunity(
            Name = '일반고객 - 추가 완료',
            AccountId = testAccounts[2].Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-5),
            Amount = 15000000, // 1천500만원
            Type = 'Renewal'
        )
    };
    insert testOpps;
    System.debug('✅ Opportunity 생성: ' + testOpps.size() + '개');
    
    // 5. 고객 건강도용 Case 생성
    System.debug('🏥 고객 건강도 분석용 Case 생성...');
    
    List<Case> testCases = new List<Case>{
        // 위험 고객용 Case (2개로 위험 분류)
        new Case(
            AccountId = testAccounts[3].Id,
            Subject = '시스템 오류 발생',
            Status = 'New',
            Priority = 'High'
        ),
        new Case(
            AccountId = testAccounts[3].Id,
            Subject = '성능 저하 문의',
            Status = 'Working',
            Priority = 'Medium'
        )
    };
    insert testCases;
    System.debug('✅ Case 생성: ' + testCases.size() + '개');
    
    // 6. 최종 검증
    System.debug('');
    System.debug('📊 === 최종 데이터 검증 ===');
    
    // Asset 검증 (1일 조건 만족 여부)
    List<Asset> verifyAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
        FROM Asset 
        WHERE Status = 'Installed'
        AND InstallDate <= :Date.today().addDays(-1) // 1일 조건
        ORDER BY Price DESC
    ];
    
    System.debug('✅ 1일 조건 만족 Asset: ' + verifyAssets.size() + '개');
    for(Asset a : verifyAssets) {
        Integer daysFromInstall = a.InstallDate.daysBetween(Date.today());
        System.debug('  - ' + a.Name + ': ' + daysFromInstall + '일 경과, 가격: ' + a.Price);
    }
    
    // Opportunity 검증 (월간 성과)
    Date thisMonth = Date.today().toStartOfMonth();
    Integer completedCount = [SELECT COUNT() FROM Opportunity WHERE StageName = 'Closed Won' AND CloseDate >= :thisMonth AND CloseDate <= :Date.today()];
    Integer inProgressCount = [SELECT COUNT() FROM Opportunity WHERE StageName != 'Closed Won' AND StageName != 'Closed Lost' AND CloseDate >= :Date.today()];
    
    System.debug('✅ 이번 달 완료된 갱신: ' + completedCount + '건');
    System.debug('✅ 진행 중인 갱신: ' + inProgressCount + '건');
    
    // 총합 계산
    AggregateResult[] completedResults = [
        SELECT SUM(Amount) sumAmount 
        FROM Opportunity 
        WHERE StageName = 'Closed Won' 
        AND CloseDate >= :thisMonth 
        AND CloseDate <= :Date.today()
    ];
    
    Decimal completedAmount = (Decimal)completedResults[0].get('sumAmount');
    System.debug('✅ 완료된 갱신 총액: ' + completedAmount);
    
} catch(Exception e) {
    System.debug('❌ 데이터 생성 중 오류: ' + e.getMessage());
    System.debug('❌ 타입: ' + e.getTypeName());
    System.debug('❌ 라인: ' + e.getLineNumber());
    System.debug('❌ 스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('🎯 === 예상 대시보드 결과 (수정 후) ===');
System.debug('💰 오늘 예상 매출: 약 7,440만원');
System.debug('  🔥 긴급고객: 4,500만원 (5,000만원 × 90%)');
System.debug('  ⚠️ 중요고객: 1,800만원 (2,000만원 × 90%)');
System.debug('  📋 일반고객: 720만원 (800만원 × 90%)');
System.debug('  📋 위험고객: 420만원 (500만원 × 84%)');
System.debug('🎯 월간 완료: 3건, 4,500만원');
System.debug('🎯 월간 진행: 1건, 2,500만원');
System.debug('🏥 건강도: 건강 75%, 위험 25%');
System.debug('🏆 실버 레벨 달성! (4,500만원)');
System.debug('');
System.debug('🚀 === 즉시 갱신 가능한 데이터 생성 완료 ===');
System.debug('💡 이제 수정된 클래스를 배포하고 대시보드를 확인하세요!');

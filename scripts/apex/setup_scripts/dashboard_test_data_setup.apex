/**
 * 성과 추적 대시보드 테스트용 데이터 생성 스크립트
 * 목적: 실제 화면에서 확인 가능한 의미있는 데이터 생성
 */

System.debug('🚀 === 성과 추적 대시보드 테스트 데이터 생성 시작 ===');

// 1단계: 테스트용 Account 생성
List<Account> testAccounts = new List<Account>();

Account account1 = new Account(
    Name = '삼성전자',
    Type = 'Customer',
    Industry = 'Technology',
    AnnualRevenue = 50000000000.00
);

Account account2 = new Account(
    Name = 'LG전자', 
    Type = 'Customer',
    Industry = 'Technology',
    AnnualRevenue = 30000000000.00
);

Account account3 = new Account(
    Name = '현대자동차',
    Type = 'Customer', 
    Industry = 'Automotive',
    AnnualRevenue = 40000000000.00
);

Account account4 = new Account(
    Name = 'SK텔레콤',
    Type = 'Customer',
    Industry = 'Telecommunications', 
    AnnualRevenue = 20000000000.00
);

Account account5 = new Account(
    Name = '네이버',
    Type = 'Customer',
    Industry = 'Technology',
    AnnualRevenue = 5000000000.00
);

testAccounts.add(account1);
testAccounts.add(account2);
testAccounts.add(account3);
testAccounts.add(account4);
testAccounts.add(account5);

try {
    insert testAccounts;
    System.debug('✅ 테스트 Account 생성 완료: ' + testAccounts.size() + '개');
    
    // 2단계: 다양한 시나리오의 Asset 생성
    List<Asset> testAssets = new List<Asset>();
    
    // 시나리오 1: 갱신 임박 고액 자산 (우선순위 높음)
    Asset asset1 = new Asset(
        Name = 'Enterprise Server 시스템',
        AccountId = testAccounts[0].Id,
        Status = 'Installed',
        Price = 15000000, // 1,500만원
        Quantity = 2,
        InstallDate = Date.today().addDays(-350), // 350일 전 설치
        UsageEndDate = Date.today().addDays(15), // 15일 후 만료 - 갱신 임박!
        Description = '핵심 업무 시스템 - 갱신 필수'
    );
    
    Asset asset2 = new Asset(
        Name = 'CRM 소프트웨어 라이선스',
        AccountId = testAccounts[1].Id,
        Status = 'Installed', 
        Price = 8000000, // 800만원
        Quantity = 1,
        InstallDate = Date.today().addDays(-340),
        UsageEndDate = Date.today().addDays(25), // 25일 후 만료
        Description = '영업팀 필수 도구'
    );
    
    // 시나리오 2: 고액 자산이지만 여유 있는 갱신 (중간 우선순위)
    Asset asset3 = new Asset(
        Name = '클라우드 인프라 서비스',
        AccountId = testAccounts[2].Id,
        Status = 'Installed',
        Price = 25000000, // 2,500만원 - 고액!
        Quantity = 1, 
        InstallDate = Date.today().addDays(-300),
        UsageEndDate = Date.today().addDays(60), // 60일 후 만료
        Description = '전사 클라우드 플랫폼'
    );
    
    Asset asset4 = new Asset(
        Name = '보안 솔루션',
        AccountId = testAccounts[3].Id,
        Status = 'Installed',
        Price = 12000000, // 1,200만원
        Quantity = 1,
        InstallDate = Date.today().addDays(-320),
        UsageEndDate = Date.today().addDays(45), // 45일 후 만료
        Description = '네트워크 보안 시스템'
    );
    
    // 시나리오 3: 소액이지만 갱신 임박 (낮은 우선순위)
    Asset asset5 = new Asset(
        Name = '오피스 소프트웨어',
        AccountId = testAccounts[4].Id,
        Status = 'Installed',
        Price = 500000, // 50만원 - 소액
        Quantity = 10,
        InstallDate = Date.today().addDays(-365),
        UsageEndDate = Date.today().addDays(10), // 10일 후 만료
        Description = '사무용 소프트웨어 패키지'
    );
    
    // 시나리오 4: 여유 있는 갱신 (참고용)
    Asset asset6 = new Asset(
        Name = '데이터베이스 라이선스',
        AccountId = testAccounts[0].Id,
        Status = 'Installed',
        Price = 18000000, // 1,800만원
        Quantity = 1,
        InstallDate = Date.today().addDays(-200),
        UsageEndDate = Date.today().addDays(165), // 165일 후 만료
        Description = '핵심 데이터베이스 시스템'
    );
    
    testAssets.add(asset1);
    testAssets.add(asset2);
    testAssets.add(asset3);
    testAssets.add(asset4);
    testAssets.add(asset5);
    testAssets.add(asset6);
    
    insert testAssets;
    System.debug('✅ 테스트 Asset 생성 완료: ' + testAssets.size() + '개');
    
    // 3단계: 월간 성과를 위한 Opportunity 생성
    List<Opportunity> testOpportunities = new List<Opportunity>();
    
    // 완료된 갱신 (이번 달)
    Opportunity completedOpp1 = new Opportunity(
        Name = '삼성전자 - 서버 시스템 갱신',
        AccountId = testAccounts[0].Id,
        StageName = 'Closed Won',
        CloseDate = Date.today().addDays(-5), // 5일 전 완료
        Amount = 20000000, // 2,000만원
        Type = 'Renewal',
        Description = '성공적으로 완료된 갱신'
    );
    
    Opportunity completedOpp2 = new Opportunity(
        Name = 'LG전자 - 소프트웨어 갱신',
        AccountId = testAccounts[1].Id,
        StageName = 'Closed Won', 
        CloseDate = Date.today().addDays(-10), // 10일 전 완료
        Amount = 15000000, // 1,500만원
        Type = 'Renewal',
        Description = '성공적으로 완료된 갱신'
    );
    
    // 진행 중인 갱신
    Opportunity inProgressOpp1 = new Opportunity(
        Name = '현대자동차 - 클라우드 갱신',
        AccountId = testAccounts[2].Id,
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30), // 30일 후 예정
        Amount = 30000000, // 3,000만원
        Type = 'Renewal',
        Description = '진행 중인 갱신 프로세스'
    );
    
    Opportunity inProgressOpp2 = new Opportunity(
        Name = 'SK텔레콤 - 보안 솔루션 갱신',
        AccountId = testAccounts[3].Id,
        StageName = 'Qualification',
        CloseDate = Date.today().addDays(45), // 45일 후 예정
        Amount = 18000000, // 1,800만원
        Type = 'Renewal', 
        Description = '진행 중인 갱신 프로세스'
    );
    
    testOpportunities.add(completedOpp1);
    testOpportunities.add(completedOpp2);
    testOpportunities.add(inProgressOpp1);  
    testOpportunities.add(inProgressOpp2);
    
    insert testOpportunities;
    System.debug('✅ 테스트 Opportunity 생성 완료: ' + testOpportunities.size() + '개');
    
    // 4단계: 고객 건강도를 위한 Case 생성
    List<Case> testCases = new List<Case>();
    
    // 문제 있는 고객 (위험)
    Case case1 = new Case(
        AccountId = testAccounts[4].Id, // 네이버
        Subject = '시스템 성능 저하 문제',
        Status = 'New',
        Priority = 'High',
        Origin = 'Phone',
        Description = '시스템 응답 속도가 현저히 느려짐'
    );
    
    Case case2 = new Case(
        AccountId = testAccounts[4].Id, // 네이버 (같은 고객)
        Subject = '로그인 오류 발생',
        Status = 'Working',
        Priority = 'Medium',
        Origin = 'Email',
        Description = '특정 사용자 로그인 불가 현상'
    );
    
    Case case3 = new Case(
        AccountId = testAccounts[4].Id, // 네이버 (같은 고객 - 3개 Case로 위험 고객)
        Subject = '데이터 동기화 문제', 
        Status = 'New',
        Priority = 'Medium',
        Origin = 'Web',
        Description = '데이터 동기화 지연 발생'
    );
    
    // 주의 필요 고객 (경미한 문제)
    Case case4 = new Case(
        AccountId = testAccounts[3].Id, // SK텔레콤
        Subject = '사용자 교육 요청',
        Status = 'Working',
        Priority = 'Low',
        Origin = 'Email',
        Description = '신규 기능 사용법 문의'
    );
    
    testCases.add(case1);
    testCases.add(case2);
    testCases.add(case3);
    testCases.add(case4);
    
    insert testCases;
    System.debug('✅ 테스트 Case 생성 완료: ' + testCases.size() + '개');
    
    // 5단계: 생성된 데이터 요약 출력
    System.debug('');
    System.debug('📊 === 생성된 테스트 데이터 요약 ===');
    System.debug('🏢 Account: ' + testAccounts.size() + '개 (대기업 고객)');
    System.debug('💼 Asset: ' + testAssets.size() + '개 (다양한 갱신 시나리오)');
    System.debug('💰 Opportunity: ' + testOpportunities.size() + '개 (완료 2건, 진행 2건)');
    System.debug('🎫 Case: ' + testCases.size() + '개 (고객 건강도 테스트용)');
    System.debug('');
    System.debug('🎯 예상 대시보드 결과:');
    System.debug('  💰 오늘 예상 매출: 약 6,600만원 (고액 자산들의 80% 확률)');
    System.debug('  🎯 월간 완료: 2건 (3,500만원)');
    System.debug('  🎯 월간 진행: 2건 (4,800만원)');
    System.debug('  🟢 건강 고객: 3명 (삼성, LG, 현대)');
    System.debug('  🟡 주의 고객: 1명 (SK텔레콤)');
    System.debug('  🔴 위험 고객: 1명 (네이버)');
    System.debug('  🏆 레벨: 실버 달성 (완료 3,500만원)');
    
} catch(Exception e) {
    System.debug('❌ 테스트 데이터 생성 실패: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

System.debug('🚀 === 성과 추적 대시보드 테스트 데이터 생성 완료 ===');
System.debug('💡 이제 대시보드를 새로고침하여 결과를 확인하세요!');

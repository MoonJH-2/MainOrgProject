/**
 * Salesforce Sales Assets 화면 테스트용 실제 데이터 생성
 * 실행: Developer Console > Execute Anonymous
 * 목적: 성과 추적 대시보드에서 실제 값 확인
 */

System.debug('🚀 === Sales Assets 테스트 데이터 생성 시작 ===');

try {
    // 1. 테스트용 Account 생성 (실제 회사명 사용)
    List<Account> accounts = new List<Account>();
    
    accounts.add(new Account(
        Name = '삼성전자',
        Type = 'Customer',
        Industry = 'Technology',
        Phone = '02-2255-0114',
        BillingCity = '수원',
        BillingState = '경기도',
        AnnualRevenue = 200000000000.00
    ));
    
    accounts.add(new Account(
        Name = 'LG디스플레이',
        Type = 'Customer', 
        Industry = 'Manufacturing',
        Phone = '02-3777-1114',
        BillingCity = '서울',
        BillingState = '서울특별시',
        AnnualRevenue = 150000000000.00
    ));
    
    accounts.add(new Account(
        Name = '네이버',
        Type = 'Customer',
        Industry = 'Technology',
        Phone = '1588-3820',
        BillingCity = '성남',
        BillingState = '경기도',
        AnnualRevenue = 50000000000.00
    ));
    
    accounts.add(new Account(
        Name = '카카오',
        Type = 'Customer',
        Industry = 'Technology', 
        Phone = '1577-3754',
        BillingCity = '성남',
        BillingState = '경기도',
        AnnualRevenue = 30000000000.00
    ));
    
    accounts.add(new Account(
        Name = '현대자동차',
        Type = 'Customer',
        Industry = 'Automotive',
        Phone = '02-746-1114',
        BillingCity = '서울',
        BillingState = '서울특별시',
        AnnualRevenue = 100000000000.00
    ));
    
    insert accounts;
    System.debug('✅ Account 생성 완료: ' + accounts.size() + '개');
    
    // 2. 우선순위 테스트를 위한 Asset 생성 (갱신 임박도별 분류)
    List<Asset> assets = new List<Asset>();
    
    // 🔥 초긴급 (갱신 임박 + 고액) - 우선순위 1위
    assets.add(new Asset(
        Name = '엔터프라이즈 ERP 시스템',
        AccountId = accounts[0].Id, // 삼성전자
        Status = 'Installed',
        Price = 50000000, // 5천만원
        Quantity = 1,
        InstallDate = Date.today().addDays(-355), // 355일 전 설치
        UsageEndDate = Date.today().addDays(10), // 10일 후 만료!
        Description = '전사 ERP 시스템 - 갱신 필수',
        SerialNumber = 'ERP-2024-001'
    ));
    
    // 🔥 긴급 (갱신 임박 + 중액) - 우선순위 2위  
    assets.add(new Asset(
        Name = 'CRM 플랫폼 라이선스',
        AccountId = accounts[1].Id, // LG디스플레이
        Status = 'Installed',
        Price = 15000000, // 1천500만원
        Quantity = 1,
        InstallDate = Date.today().addDays(-340),
        UsageEndDate = Date.today().addDays(20), // 20일 후 만료
        Description = '영업팀 필수 CRM 도구',
        SerialNumber = 'CRM-2024-002'
    ));
    
    // 🟡 중요 (여유 있지만 고액) - 우선순위 3위
    assets.add(new Asset(
        Name = '클라우드 인프라 서비스',
        AccountId = accounts[2].Id, // 네이버
        Status = 'Installed', 
        Price = 80000000, // 8천만원 (초고액!)
        Quantity = 1,
        InstallDate = Date.today().addDays(-300),
        UsageEndDate = Date.today().addDays(65), // 65일 후 만료
        Description = '전사 클라우드 플랫폼',
        SerialNumber = 'CLOUD-2024-003'
    ));
    
    // 🟡 중요 (갱신 임박 + 중액) - 우선순위 4위
    assets.add(new Asset(
        Name = '보안 솔루션 패키지',
        AccountId = accounts[3].Id, // 카카오
        Status = 'Installed',
        Price = 25000000, // 2천500만원
        Quantity = 1,
        InstallDate = Date.today().addDays(-330),
        UsageEndDate = Date.today().addDays(30), // 30일 후 만료
        Description = '통합 보안 솔루션',
        SerialNumber = 'SEC-2024-004'
    ));
    
    // 🟢 일반 (소액) - 우선순위 5위
    assets.add(new Asset(
        Name = '오피스 소프트웨어 패키지',
        AccountId = accounts[4].Id, // 현대자동차
        Status = 'Installed',
        Price = 3000000, // 300만원
        Quantity = 50,
        InstallDate = Date.today().addDays(-365),
        UsageEndDate = Date.today().addDays(15), // 15일 후 만료
        Description = '임직원용 오피스 도구',
        SerialNumber = 'OFFICE-2024-005'
    ));
    
    // 참고용 (갱신 여유 있음)
    assets.add(new Asset(
        Name = 'AI 분석 플랫폼',
        AccountId = accounts[0].Id, // 삼성전자
        Status = 'Installed',
        Price = 40000000, // 4천만원
        Quantity = 1,
        InstallDate = Date.today().addDays(-180),
        UsageEndDate = Date.today().addDays(185), // 185일 후 만료
        Description = '빅데이터 분석 시스템',
        SerialNumber = 'AI-2024-006'
    ));
    
    insert assets;
    System.debug('✅ Asset 생성 완료: ' + assets.size() + '개');
    
    // 3. 월간 성과를 위한 Opportunity 생성
    List<Opportunity> opportunities = new List<Opportunity>();
    
    // 이번 달 완료된 갱신 (성과 점수 계산용)
    opportunities.add(new Opportunity(
        Name = '삼성전자 - 데이터베이스 갱신',
        AccountId = accounts[0].Id,
        StageName = 'Closed Won',
        CloseDate = Date.today().addDays(-5),
        Amount = 30000000, // 3천만원
        Type = 'Renewal',
        Description = '성공적으로 완료된 갱신',
        Probability = 100
    ));
    
    opportunities.add(new Opportunity(
        Name = 'LG디스플레이 - 모니터링 시스템 갱신',
        AccountId = accounts[1].Id,
        StageName = 'Closed Won',
        CloseDate = Date.today().addDays(-12),
        Amount = 18000000, // 1천800만원
        Type = 'Renewal', 
        Description = '성공적으로 완료된 갱신',
        Probability = 100
    ));
    
    // 진행 중인 갱신
    opportunities.add(new Opportunity(
        Name = '네이버 - 클라우드 확장 갱신',
        AccountId = accounts[2].Id,
        StageName = 'Proposal/Price Quote', 
        CloseDate = Date.today().addDays(35),
        Amount = 90000000, // 9천만원
        Type = 'Renewal',
        Description = '진행 중인 고액 갱신',
        Probability = 75
    ));
    
    opportunities.add(new Opportunity(
        Name = '카카오 - 보안 업그레이드',
        AccountId = accounts[3].Id,
        StageName = 'Negotiation/Review',
        CloseDate = Date.today().addDays(25),
        Amount = 35000000, // 3천500만원
        Type = 'Renewal',
        Description = '진행 중인 갱신',
        Probability = 85
    ));
    
    // 신규 기회
    opportunities.add(new Opportunity(
        Name = '현대자동차 - 신규 솔루션 도입',
        AccountId = accounts[4].Id,
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(60),
        Amount = 45000000, // 4천500만원
        Type = 'New Business',
        Description = '신규 사업 기회',
        Probability = 60
    ));
    
    insert opportunities;
    System.debug('✅ Opportunity 생성 완료: ' + opportunities.size() + '개');
    
    // 4. 고객 건강도 분석용 Case 생성
    List<Case> cases = new List<Case>();
    
    // 위험 고객 (Case 많음)
    cases.add(new Case(
        AccountId = accounts[4].Id, // 현대자동차
        Subject = '시스템 성능 저하 이슈',
        Status = 'New',
        Priority = 'High',
        Origin = 'Phone',
        Description = '오피스 소프트웨어 응답 속도 문제'
    ));
    
    cases.add(new Case(
        AccountId = accounts[4].Id, // 현대자동차 (같은 고객)
        Subject = '라이선스 인증 오류',
        Status = 'Working', 
        Priority = 'Medium',
        Origin = 'Email',
        Description = '일부 사용자 라이선스 인증 실패'
    ));
    
    cases.add(new Case(
        AccountId = accounts[4].Id, // 현대자동차 (같은 고객 - 총 3개로 위험)
        Subject = '업데이트 설치 문제',
        Status = 'New',
        Priority = 'Low',
        Origin = 'Web',
        Description = '최신 업데이트 설치 오류'
    ));
    
    // 주의 고객 (Case 적음)
    cases.add(new Case(
        AccountId = accounts[3].Id, // 카카오
        Subject = '사용자 교육 요청',
        Status = 'Working',
        Priority = 'Low', 
        Origin = 'Email',
        Description = '신규 기능 교육 요청'
    ));
    
    cases.add(new Case(
        AccountId = accounts[1].Id, // LG디스플레이
        Subject = '기술 문의',
        Status = 'Closed',
        Priority = 'Low',
        Origin = 'Phone', 
        Description = '기능 관련 문의 (해결 완료)'
    ));
    
    insert cases;
    System.debug('✅ Case 생성 완료: ' + cases.size() + '개');
    
    // 5. Task 생성 (업무 효율성 측정용)
    List<Task> tasks = new List<Task>();
    
    // 완료된 갱신 관련 작업들
    tasks.add(new Task(
        Subject = '삼성전자 갱신 미팅',
        WhatId = opportunities[0].Id,
        Status = 'Completed',
        Priority = 'High',
        ActivityDate = Date.today().addDays(-3),
        Description = '갱신 계약 논의 완료'
    ));
    
    tasks.add(new Task(
        Subject = 'LG디스플레이 계약서 검토',
        WhatId = opportunities[1].Id, 
        Status = 'Completed',
        Priority = 'Normal',
        ActivityDate = Date.today().addDays(-8),
        Description = '계약 조건 검토 및 승인'
    ));
    
    // 진행 중인 작업들
    tasks.add(new Task(
        Subject = '네이버 제안서 준비',
        WhatId = opportunities[2].Id,
        Status = 'In Progress', 
        Priority = 'High',
        ActivityDate = Date.today().addDays(2),
        Description = '클라우드 확장 제안서 작성'
    ));
    
    tasks.add(new Task(
        Subject = '카카오 기술 검토',
        WhatId = opportunities[3].Id,
        Status = 'Not Started',
        Priority = 'Normal',
        ActivityDate = Date.today().addDays(5),
        Description = '보안 솔루션 기술적 검토'
    ));
    
    insert tasks;
    System.debug('✅ Task 생성 완료: ' + tasks.size() + '개');
    
    // 6. 생성된 데이터 요약 및 예상 결과
    System.debug('');
    System.debug('📊 === 생성된 테스트 데이터 요약 ===');
    System.debug('🏢 Account: ' + accounts.size() + '개 - 실제 한국 대기업');
    System.debug('💼 Asset: ' + assets.size() + '개 - 다양한 갱신 시나리오');
    System.debug('💰 Opportunity: ' + opportunities.size() + '개 - 완료 2건, 진행 3건');
    System.debug('🎫 Case: ' + cases.size() + '개 - 고객 건강도 분석용');
    System.debug('📋 Task: ' + tasks.size() + '개 - 업무 효율성 측정용');
    System.debug('');
    
    System.debug('🎯 === 예상 대시보드 결과 ===');
    System.debug('💰 오늘의 예상 매출:');
    System.debug('  - 삼성전자 ERP: 5,000만원 × 95% = 4,750만원');
    System.debug('  - LG CRM: 1,500만원 × 90% = 1,350만원'); 
    System.debug('  - 네이버 클라우드: 8,000만원 × 75% = 6,000만원');
    System.debug('  - 카카오 보안: 2,500만원 × 85% = 2,125만원');
    System.debug('  - 현대차 오피스: 300만원 × 70% = 210만원');
    System.debug('  📈 총 예상 매출: 약 1억 4,435만원');
    System.debug('');
    
    System.debug('🎯 이번 달 갱신 현황:');
    System.debug('  ✅ 완료: 2건, 4,800만원 (삼성 3,000만 + LG 1,800만)');
    System.debug('  🔄 진행: 3건, 17,000만원 (네이버 9,000만 + 카카오 3,500만 + 현대 4,500만)');
    System.debug('  📊 예상 총: 2억 1,800만원');
    System.debug('');
    
    System.debug('🏥 고객 건강도 분포:');
    System.debug('  🟢 건강: 2명 (40%) - 삼성, 네이버');
    System.debug('  🟡 주의: 2명 (40%) - LG, 카카오'); 
    System.debug('  🔴 위험: 1명 (20%) - 현대자동차');
    System.debug('');
    
    System.debug('🏆 레벨 시스템:');
    System.debug('  현재 매출: 4,800만원 (완료 기준)');
    System.debug('  🥈 실버 레벨 달성! (3,000만원 이상)');
    System.debug('  다음 목표: 🥇 골드 (5,000만원) - 200만원 남음');
    
} catch(Exception e) {
    System.debug('❌ 테스트 데이터 생성 실패: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

System.debug('');
System.debug('🚀 === 테스트 데이터 생성 완료 ===');
System.debug('💡 이제 Assets Performance 대시보드를 새로고침하세요!');
System.debug('🔗 Apps > Sales > Assets Performance로 이동하여 확인하세요.');

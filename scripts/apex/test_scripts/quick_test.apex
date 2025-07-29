/**
 * 즉시 실행용 간단 테스트 데이터
 * 목적: 5분 내에 대시보드 결과 확인
 */

// 1. 빠른 Account 생성
Account testAccount = new Account(Name = '테스트기업', Type = 'Customer');
insert testAccount;

// 2. 긴급 갱신 Asset (우선순위 1위가 될 것)
Asset urgentAsset = new Asset(
    Name = '긴급 갱신 시스템',
    AccountId = testAccount.Id,
    Status = 'Installed',
    Price = 30000000, // 3천만원
    InstallDate = Date.today().addDays(-350),
    UsageEndDate = Date.today().addDays(5) // 5일 후 만료!
);
insert urgentAsset;

// 3. 완료된 갱신 (월간 성과용)
Opportunity completedDeal = new Opportunity(
    Name = '완료된 갱신',
    AccountId = testAccount.Id,
    StageName = 'Closed Won',
    CloseDate = Date.today().addDays(-3),
    Amount = 25000000, // 2천500만원
    Type = 'Renewal'
);
insert completedDeal;

// 4. 진행 중인 갱신
Opportunity inProgress = new Opportunity(
    Name = '진행 중인 갱신',
    AccountId = testAccount.Id,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    Amount = 40000000, // 4천만원
    Type = 'Renewal'
);
insert inProgress;

System.debug('✅ 간단 테스트 데이터 생성 완료!');
System.debug('💰 예상 오늘 매출: 2,700만원 (3천만원 × 90%)');
System.debug('🎯 월간 완료: 1건, 2,500만원');
System.debug('🎯 월간 진행: 1건, 4,000만원');
System.debug('🏆 현재 레벨: 브론즈에서 실버로 업그레이드!');
System.debug('🔄 이제 대시보드를 새로고침하세요!');

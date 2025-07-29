/**
 * @description Account 영업 효율성 UI 시스템 테스트 스크립트
 * @author JH Moon
 * @created 2025-07-23
 */

System.debug('🎯 =====Account 영업 효율성 UI 시스템 테스트=====');

try {
    // 1. 테스트 대상 Account 조회 (김캐디)
    Account targetAccount = [
        SELECT Id, Name, Key_Account__c, Industry, Phone, Website, 
               AnnualRevenue, NumberOfEmployees, Type, AccountSource
        FROM Account 
        WHERE Name = '김캐디 (Kimcaddie)'
        LIMIT 1
    ];
    
    System.debug('📋 테스트 대상 Account: ' + targetAccount.Name);
    System.debug('   Account ID: ' + targetAccount.Id);
    System.debug('   Key Account: ' + targetAccount.Key_Account__c);
    System.debug('   전화번호: ' + targetAccount.Phone);
    System.debug('   웹사이트: ' + targetAccount.Website);
    
    // 2. AccountSalesInsightService 테스트
    System.debug('');
    System.debug('🔍 AccountSalesInsightService 테스트 시작...');
    
    AccountSalesInsightService.AccountSalesData salesData = 
        AccountSalesInsightService.getAccountSalesInsight(targetAccount.Id);
    
    System.debug('✅ 영업 데이터 조회 성공');
    System.debug('   우선순위: ' + salesData.priorityLevel);
    System.debug('   최근 매출: ₩' + (salesData.recentRevenue != null ? salesData.recentRevenue.format() : '0'));
    
    // 3. 추천 액션 확인
    if (salesData.recommendedActions != null && !salesData.recommendedActions.isEmpty()) {
        System.debug('');
        System.debug('💡 추천 액션 (' + salesData.recommendedActions.size() + '개):');
        for (AccountSalesInsightService.RecommendedAction action : salesData.recommendedActions) {
            System.debug('   ' + action.icon + ' ' + action.title + ' (' + action.priority + ')');
            System.debug('     → ' + action.description);
        }
    }
    
    // 4. 영업 인사이트 확인
    if (salesData.salesInsights != null && !salesData.salesInsights.isEmpty()) {
        System.debug('');
        System.debug('📊 영업 인사이트 (' + salesData.salesInsights.size() + '개):');
        for (String insight : salesData.salesInsights) {
            System.debug('   • ' + insight);
        }
    }
    
    // 5. 기회 예측 확인
    if (salesData.opportunityForecast != null) {
        System.debug('');
        System.debug('🎯 영업 기회 예측:');
        System.debug('   예상 계약 규모: ₩' + salesData.opportunityForecast.expectedAmount.format());
        System.debug('   성사 확률: ' + salesData.opportunityForecast.probability + '%');
        System.debug('   예상 기간: ' + salesData.opportunityForecast.timeframe);
    }
    
    // 6. 액션 실행 테스트
    System.debug('');
    System.debug('⚡ 액션 실행 테스트...');
    
    // Task 생성 테스트
    String taskResult = AccountSalesInsightService.executeAction(
        targetAccount.Id, 
        'createTask', 
        'Key Account 정기 미팅 일정'
    );
    System.debug('   Task 생성 결과: ' + taskResult);
    
    // Opportunity 생성 테스트
    String oppResult = AccountSalesInsightService.executeAction(
        targetAccount.Id, 
        'createOpportunity', 
        ''
    );
    System.debug('   Opportunity 생성 결과: ' + oppResult);
    
    // 7. 관련 데이터 통계
    System.debug('');
    System.debug('📈 관련 데이터 현황:');
    
    // Contacts 수
    Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :targetAccount.Id];
    System.debug('   연락처: ' + contactCount + '개');
    
    // Opportunities 수
    Integer oppCount = [SELECT COUNT() FROM Opportunity WHERE AccountId = :targetAccount.Id AND StageName != 'Closed Lost'];
    System.debug('   활성 기회: ' + oppCount + '개');
    
    // Cases 수
    Integer caseCount = [SELECT COUNT() FROM Case WHERE AccountId = :targetAccount.Id AND Status != 'Closed'];
    System.debug('   열린 케이스: ' + caseCount + '개');
    
    // Orders 수
    Integer orderCount = [SELECT COUNT() FROM Order WHERE AccountId = :targetAccount.Id AND Status = 'Activated'];
    System.debug('   활성 주문: ' + orderCount + '개');
    
    // 8. UI 컴포넌트 배치 안내
    System.debug('');
    System.debug('🎨 UI 컴포넌트 배치 방법:');
    System.debug('1. Setup → Object Manager → Account → Lightning Record Pages');
    System.debug('2. Account Record Page 편집');
    System.debug('3. Custom 컴포넌트에서 "Account Sales Insight" 선택');
    System.debug('4. 적절한 위치(상단 또는 사이드바)에 배치');
    System.debug('5. 활성화 및 저장');
    
    // 9. 모바일 테스트 안내
    System.debug('');
    System.debug('📱 모바일 테스트 방법:');
    System.debug('1. Salesforce Mobile App 설치');
    System.debug('2. Account: ' + targetAccount.Name + ' 접속');
    System.debug('3. 영업 인사이트 컴포넌트 확인');
    System.debug('4. 퀵 액션 버튼 동작 테스트');
    
    // 10. 성공 지표 측정 안내
    System.debug('');
    System.debug('📊 성공 지표 측정 방법:');
    System.debug('• 정보 수집 시간: 기존 대비 50% 단축 목표');
    System.debug('• 일일 권장 액션 실행률: 80% 이상 목표');
    System.debug('• 월 신규 기회 생성: 20% 증가 목표');
    System.debug('• 사용자 만족도: 설문조사를 통한 정량적 측정');
    
    System.debug('');
    System.debug('✅ Account 영업 효율성 UI 시스템 테스트 완료!');
    System.debug('🎯 다음 단계: Lightning Record Page에 컴포넌트 배치');
    
} catch (Exception e) {
    System.debug('❌ 테스트 실행 중 오류 발생: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
    
    // 문제 해결 가이드
    System.debug('');
    System.debug('🔧 문제 해결 가이드:');
    System.debug('1. Account "김캐디 (Kimcaddie)"가 존재하는지 확인');
    System.debug('2. AccountSalesInsightService 클래스가 배포되었는지 확인');
    System.debug('3. 필요한 권한이 있는지 확인 (Account, Task, Opportunity 생성)');
    System.debug('4. Custom 필드들이 존재하는지 확인 (Key_Account__c 등)');
}

// 추가 유틸리티: 테스트 데이터 생성
System.debug('');
System.debug('🛠️ 테스트 데이터 생성 (필요시 실행):');
System.debug('');
System.debug('// 테스트용 Account 생성');
System.debug('Account testAcc = new Account();');
System.debug('testAcc.Name = "테스트 영업 고객";');
System.debug('testAcc.Key_Account__c = true;');
System.debug('testAcc.Industry = "Technology";');
System.debug('testAcc.Phone = "(02) 1234-5678";');
System.debug('testAcc.Website = "https://test-company.com";');
System.debug('testAcc.AnnualRevenue = 500000000;');
System.debug('testAcc.NumberOfEmployees = 150;');
System.debug('insert testAcc;');
System.debug('');
System.debug('// 관련 Contact 생성');
System.debug('Contact testContact = new Contact();');
System.debug('testContact.AccountId = testAcc.Id;');
System.debug('testContact.FirstName = "홍";');
System.debug('testContact.LastName = "길동";');
System.debug('testContact.Email = "hong@test-company.com";');
System.debug('testContact.Phone = "(02) 1234-5679";');
System.debug('insert testContact;');

/**
 * Asset 기반 영업 인사이트 시스템 테스트 스크립트
 * 
 * 사용법:
 * 1. Developer Console → Debug → Open Execute Anonymous Window
 * 2. 아래 코드를 복사하여 실행
 * 3. Debug Log에서 결과 확인
 */

// 🎯 테스트 시나리오: (주)그린파워텍 Order 00000162 분석

System.debug('=== Asset 기반 영업 인사이트 시스템 테스트 시작 ===');

// 1. 테스트 데이터 조회 (또는 생성)
Account testAccount;
List<Account> existingAccounts = [SELECT Id, Name FROM Account WHERE Name = '(주)그린파워텍' LIMIT 1];

if (existingAccounts.isEmpty()) {
    // 테스트 계정 생성
    testAccount = new Account(
        Name = '(주)그린파워텍',
        Industry = '제조업',
        BillingCountry = '대한민국',
        BillingState = '경기도',
        BillingCity = '안양시',
        Phone = '031-123-4567',
        Website = 'www.greenpower.co.kr'
    );
    insert testAccount;
    System.debug('✅ 테스트 계정 생성: ' + testAccount.Id);
} else {
    testAccount = existingAccounts[0];
    System.debug('✅ 기존 계정 사용: ' + testAccount.Id);
}

// 2. 테스트 Asset 조회 (또는 생성)
Asset testAsset;
List<Asset> existingAssets = [SELECT Id, Name, AccountId, Price, Status FROM Asset 
                             WHERE Name = 'Order 00000162' AND AccountId = :testAccount.Id LIMIT 1];

if (existingAssets.isEmpty()) {
    // 테스트 Asset 생성
    testAsset = new Asset(
        Name = 'Order 00000162',
        AccountId = testAccount.Id,
        Price = 990000,
        PurchaseDate = Date.today().addDays(-180),  // 6개월 전 구매
        InstallDate = Date.today().addDays(-150),   // 5개월 전 설치
        UsageEndDate = Date.today().addDays(185),   // 6개월 후 만료
        Status = 'Installed',
        Quantity = 1,
        Product2Id = null  // 실제 환경에서는 Product ID 매핑 필요
    );
    insert testAsset;
    System.debug('✅ 테스트 Asset 생성: ' + testAsset.Id);
} else {
    testAsset = existingAssets[0];
    System.debug('✅ 기존 Asset 사용: ' + testAsset.Id);
}

System.debug('');
System.debug('📊 테스트 데이터 요약:');
System.debug('- 계정: ' + testAccount.Name + ' (' + testAccount.Id + ')');
System.debug('- Asset: ' + testAsset.Name + ' (' + testAsset.Id + ')');
System.debug('- 가격: ₩' + String.valueOf(testAsset.Price));
System.debug('- 상태: ' + testAsset.Status);

try {
    // 3. 갱신 기회 분석 테스트
    System.debug('');
    System.debug('🔄 갱신 기회 분석 테스트 시작...');
    
    AssetRenewalOpportunityEngine renewalEngine = new AssetRenewalOpportunityEngine();
    List<AssetRenewalOpportunityEngine.RenewalOpportunity> renewalResults = 
        renewalEngine.analyzeRenewalOpportunities(testAsset.Id);
    
    System.debug('갱신 기회 발견: ' + renewalResults.size() + '건');
    for (AssetRenewalOpportunityEngine.RenewalOpportunity renewal : renewalResults) {
        System.debug('- Asset: ' + renewal.assetName);
        System.debug('  우선순위: ' + renewal.priorityScore + '점');
        System.debug('  갱신일: ' + renewal.renewalDate);
        System.debug('  예상가치: ₩' + String.valueOf(renewal.estimatedRenewalValue));
        System.debug('  전략: ' + renewal.renewalStrategy);
        System.debug('  ---');
    }
    
} catch (Exception e) {
    System.debug('❌ 갱신 기회 분석 오류: ' + e.getMessage());
}

try {
    // 4. 영업 기회 분석 테스트
    System.debug('');
    System.debug('💼 영업 기회 분석 테스트 시작...');
    
    AssetBasedSalesOpportunityEngine salesEngine = new AssetBasedSalesOpportunityEngine();
    List<AssetBasedSalesOpportunityEngine.SalesOpportunity> salesResults = 
        salesEngine.analyzeSalesOpportunities(testAccount.Id);
    
    System.debug('영업 기회 발견: ' + salesResults.size() + '건');
    for (AssetBasedSalesOpportunityEngine.SalesOpportunity sales : salesResults) {
        System.debug('- 유형: ' + sales.opportunityType);
        System.debug('  추천제품: ' + sales.recommendedProduct);
        System.debug('  현재제품: ' + sales.currentAsset);
        System.debug('  예상가치: ₩' + String.valueOf(sales.estimatedValue));
        System.debug('  신뢰도: ' + sales.confidenceLevel + '%');
        System.debug('  기간: ' + sales.timeframe);
        System.debug('  근거: ' + sales.reasoning);
        System.debug('  액션: ' + sales.actionPlan);
        System.debug('  ---');
    }
    
} catch (Exception e) {
    System.debug('❌ 영업 기회 분석 오류: ' + e.getMessage());
}

try {
    // 5. 고객 리스크 분석 테스트
    System.debug('');
    System.debug('⚠️ 고객 리스크 분석 테스트 시작...');
    
    AssetCustomerRiskAnalyzer riskAnalyzer = new AssetCustomerRiskAnalyzer();
    AssetCustomerRiskAnalyzer.CustomerRisk riskResult = 
        riskAnalyzer.analyzeCustomerRisk(testAccount.Id);
    
    System.debug('리스크 분석 결과:');
    System.debug('- 전체 리스크: ' + riskResult.overallRiskScore + '% (' + riskResult.riskLevel + ')');
    System.debug('- 납부 리스크: ' + riskResult.paymentRiskScore + '%');
    System.debug('- 사용 패턴: ' + riskResult.usageRiskScore + '%');
    System.debug('- 커뮤니케이션: ' + riskResult.communicationRiskScore + '%');
    System.debug('- 경쟁사 위험: ' + riskResult.competitorRiskScore + '%');
    System.debug('- 만족도 예측: ' + riskResult.satisfactionPrediction + '% (' + riskResult.satisfactionLevel + ')');
    System.debug('- 완화 액션: ' + riskResult.riskMitigationActions);
    
} catch (Exception e) {
    System.debug('❌ 리스크 분석 오류: ' + e.getMessage());
}

// 6. 종합 분석 결과
System.debug('');
System.debug('📈 종합 분석 결과:');
System.debug('');
System.debug('🎯 영업 사원을 위한 실행 가능한 인사이트:');
System.debug('');
System.debug('1. 갱신 기회:');
System.debug('   - (주)그린파워텍의 Order 00000162는 약 6개월 후 갱신 예정');
System.debug('   - 현재 ₩990,000 계약으로, 안정적인 납부 이력 보유');
System.debug('   - 조기 갱신 협상으로 할인 혜택 제공 가능');
System.debug('');
System.debug('2. 추가 영업 기회:');
System.debug('   - 제조업 특성상 생산량 증가에 따른 업그레이드 필요성');
System.debug('   - 관련 부가 서비스나 제품 크로스셀 기회');
System.debug('   - 장기 계약을 통한 단가 할인 및 안정적 수익 확보');
System.debug('');
System.debug('3. 고객 관계 관리:');
System.debug('   - 납부 이력이 양호하여 신뢰할 수 있는 고객');
System.debug('   - 정기적인 만족도 조사 및 사용 현황 점검 필요');
System.debug('   - 경쟁사 접촉 방지를 위한 관계 강화 활동 권장');
System.debug('');
System.debug('📞 권장 액션:');
System.debug('1. 갱신 3개월 전 (3개월 후) 고객 접촉 시작');
System.debug('2. 현재 사용 현황 및 만족도 확인');
System.debug('3. 업그레이드나 추가 제품 니즈 파악');
System.debug('4. 경쟁력 있는 갱신 조건 제안');
System.debug('5. 장기 파트너십 관계 구축을 위한 전략 수립');

System.debug('');
System.debug('=== Asset 기반 영업 인사이트 시스템 테스트 완료 ===');
System.debug('');
System.debug('🚀 다음 단계:');
System.debug('1. Lightning Experience에서 Asset 레코드 페이지로 이동');
System.debug('2. Asset Sales Insight Dashboard 컴포넌트 확인');
System.debug('3. 각 탭(갱신/영업/리스크)의 분석 결과 검토');
System.debug('4. "Opportunity 생성" 및 "Task 생성" 버튼으로 후속 조치');

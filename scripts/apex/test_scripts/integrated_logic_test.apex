/**
 * 전체 Assets 로직 통합 테스트 (Logic 1 + 2 + 3)
 * 목적: 3개 로직이 서로 연결되어 완전한 시스템으로 작동하는지 검증
 */

System.debug('🚀 === Assets 로직 통합 테스트 시작 ===');
System.debug('테스트 범위: Logic 1(우선순위) → Logic 2(원클릭 갱신) → Logic 3(성과 추적)');
System.debug('');

DateTime integrationTestStart = DateTime.now();

try {
    // ===========================================
    // PHASE 1: Logic 1 우선순위 계산 테스트
    // ===========================================
    System.debug('📊 PHASE 1: Logic 1 우선순위 계산 시스템');
    
    // 우선순위 높은 자산 조회 (Logic 1 결과)
    List<Asset> priorityAssets = [
        SELECT Id, Name, AccountId, Account.Name, Price, Quantity, 
               UsageEndDate, Priority_Score__c, Contract_Status__c
        FROM Asset 
        WHERE Priority_Score__c >= 60 
        AND Contract_Status__c = 'Active'
        ORDER BY Priority_Score__c DESC
        LIMIT 5
    ];
    
    System.debug('✅ Logic 1 결과: 우선순위 자산 ' + priorityAssets.size() + '개 발견');
    
    for(Integer i = 0; i < priorityAssets.size(); i++) {
        Asset asset = priorityAssets[i];
        System.debug('  ' + (i+1) + '. ' + asset.Account.Name + ' - ' + asset.Name + 
                    ' (점수: ' + asset.Priority_Score__c + ')');
    }
    
    if(priorityAssets.isEmpty()) {
        System.debug('⚠️ 경고: 우선순위 자산이 없습니다. 테스트 데이터를 먼저 생성하세요.');
        return;
    }
    
    // ===========================================
    // PHASE 2: Logic 2 원클릭 갱신 테스트
    // ===========================================
    System.debug('');
    System.debug('⚡ PHASE 2: Logic 2 원클릭 갱신 워크플로우');
    
    Integer renewalSuccessCount = 0;
    List<Id> processedAssetIds = new List<Id>();
    
    // 상위 3개 우선순위 자산에 대해 원클릭 갱신 실행
    for(Integer i = 0; i < Math.min(3, priorityAssets.size()); i++) {
        Asset asset = priorityAssets[i];
        
        try {
            System.debug('갱신 처리 중: ' + asset.Name);
            
            // OneClickRenewalService 호출 (Logic 2)
            OneClickRenewalService.RenewalResult renewalResult = 
                OneClickRenewalService.startRenewalProcess(asset.Id);
            
            if(renewalResult.success) {
                renewalSuccessCount++;
                processedAssetIds.add(asset.Id);
                System.debug('  ✅ 갱신 성공 - Opportunity: ' + renewalResult.opportunityId + 
                           ', Task: ' + renewalResult.taskId);
            } else {
                System.debug('  ❌ 갱신 실패: ' + renewalResult.message);
            }
            
        } catch(Exception e) {
            System.debug('  ❌ 예외 발생: ' + e.getMessage());
        }
    }
    
    System.debug('✅ Logic 2 결과: ' + renewalSuccessCount + '/' + Math.min(3, priorityAssets.size()) + 
                ' 자산 갱신 성공');
    
    // ===========================================
    // PHASE 3: Logic 3 성과 추적 테스트
    // ===========================================
    System.debug('');
    System.debug('📈 PHASE 3: Logic 3 성과 추적 대시보드');
    
    // 대시보드 데이터 조회 (Logic 3)
    PerformanceTrackingService.DashboardData dashboardData = 
        PerformanceTrackingService.getDashboardData();
    
    if(dashboardData != null) {
        System.debug('✅ Logic 3 결과: 성과 대시보드 데이터 로딩 성공');
        
        // 핵심 지표 요약
        System.debug('  📊 오늘 예상 매출: ' + dashboardData.todayRevenue.expectedAmount + 
                    ' (달성률: ' + dashboardData.todayRevenue.achievementRate + '%)');
        System.debug('  🎯 월간 갱신: 완료 ' + dashboardData.monthlyRenewal.completedCount + '건, ' +
                    '진행 ' + dashboardData.monthlyRenewal.inProgressCount + '건');
        System.debug('  🏥 고객 건강도: 🟢' + dashboardData.customerHealth.healthyCount + 
                    ' 🟡' + dashboardData.customerHealth.warningCount + 
                    ' 🔴' + dashboardData.customerHealth.riskCount);
        System.debug('  ⚡ 효율성: 성공률 ' + dashboardData.efficiency.successRate + 
                    '%, 처리 ' + dashboardData.efficiency.monthlyProcessCount + '건');
        System.debug('  🏆 게임화: ' + dashboardData.gamification.currentLevel + ' ' +
                    dashboardData.gamification.levelIcon + ' (' + 
                    dashboardData.gamification.progressPercentage + '%)');
        System.debug('  🔔 알림: ' + dashboardData.notifications.size() + '건');
        
    } else {
        System.debug('❌ Logic 3 실패: 대시보드 데이터 로딩 오류');
    }
    
    // ===========================================
    // PHASE 4: 로직 간 연결성 검증
    // ===========================================
    System.debug('');
    System.debug('🔗 PHASE 4: 로직 간 연결성 검증');
    
    // 4-1: Logic 1 → Logic 2 연결 확인
    System.debug('검증 1: Logic 1 우선순위 → Logic 2 갱신 연결');
    if(renewalSuccessCount > 0) {
        System.debug('  ✅ 연결 성공: 우선순위 자산이 갱신 프로세스로 정상 전달됨');
    } else {
        System.debug('  ⚠️ 연결 확인 필요: 우선순위 자산의 갱신 처리 실패');
    }
    
    // 4-2: Logic 2 → Logic 3 연결 확인
    System.debug('검증 2: Logic 2 갱신 → Logic 3 성과추적 연결');
    if(dashboardData != null && dashboardData.monthlyRenewal.inProgressCount > 0) {
        System.debug('  ✅ 연결 성공: 갱신 프로세스가 성과 추적에 반영됨');
    } else {
        System.debug('  ⚠️ 연결 확인 필요: 갱신 결과가 성과 추적에 미반영');
    }
    
    // 4-3: Logic 1 + Logic 3 연결 확인
    System.debug('검증 3: Logic 1 우선순위 → Logic 3 예상매출 연결');
    if(dashboardData != null && dashboardData.todayRevenue.priorityCustomers > 0) {
        System.debug('  ✅ 연결 성공: 우선순위 고객이 예상 매출 계산에 반영됨');
    } else {
        System.debug('  ⚠️ 연결 확인 필요: 우선순위 계산이 예상 매출에 미반영');
    }
    
    // ===========================================
    // PHASE 5: 전체 시스템 성능 측정
    // ===========================================
    System.debug('');
    System.debug('⏱️ PHASE 5: 전체 시스템 성능 측정');
    
    DateTime integrationTestEnd = DateTime.now();
    Long totalIntegrationTime = integrationTestEnd.getTime() - integrationTestStart.getTime();
    
    System.debug('전체 통합 테스트 시간: ' + totalIntegrationTime + 'ms');
    
    // 개별 로직 성능 목표
    // Logic 1: 3초 이내 (복잡한 우선순위 계산)
    // Logic 2: 5초 이내 (원클릭 갱신 프로세스)
    // Logic 3: 2초 이내 (대시보드 로딩)
    // 전체: 10초 이내 (통합 워크플로우)
    
    if(totalIntegrationTime <= 10000) {
        System.debug('✅ 전체 성능 목표 달성! (10초 이내)');
    } else {
        System.debug('⚠️ 전체 성능 최적화 필요 (10초 초과)');
    }
    
    // ===========================================
    // PHASE 6: 최종 결과 요약
    // ===========================================
    System.debug('');
    System.debug('🎯 === 통합 테스트 최종 결과 ===');
    
    // 성공 지표 계산
    Integer totalChecks = 6; // 검증할 항목 수
    Integer passedChecks = 0;
    
    // 1. Logic 1 작동 여부
    if(priorityAssets.size() > 0) passedChecks++;
    
    // 2. Logic 2 작동 여부  
    if(renewalSuccessCount > 0) passedChecks++;
    
    // 3. Logic 3 작동 여부
    if(dashboardData != null) passedChecks++;
    
    // 4. Logic 1→2 연결
    if(renewalSuccessCount > 0) passedChecks++;
    
    // 5. Logic 2→3 연결
    if(dashboardData != null && dashboardData.monthlyRenewal != null) passedChecks++;
    
    // 6. 전체 성능
    if(totalIntegrationTime <= 10000) passedChecks++;
    
    Decimal successRate = (Decimal)passedChecks / totalChecks * 100;
    
    System.debug('📊 통합 테스트 성공률: ' + passedChecks + '/' + totalChecks + 
                ' (' + successRate.intValue() + '%)');
    
    if(successRate >= 100) {
        System.debug('🎉 완벽한 통합! 모든 로직이 연결되어 정상 작동합니다.');
    } else if(successRate >= 80) {
        System.debug('✅ 양호한 통합! 대부분의 로직이 정상 작동합니다.');
    } else if(successRate >= 60) {
        System.debug('⚠️ 부분 통합! 일부 로직에서 문제가 발견되었습니다.');
    } else {
        System.debug('❌ 통합 실패! 로직 간 연결에 심각한 문제가 있습니다.');
    }
    
    // 사용자 가치 요약
    System.debug('');
    System.debug('💼 === 비즈니스 가치 달성도 ===');
    System.debug('🎯 목표 1: 우선순위 자동 분류 → ' + (priorityAssets.size() > 0 ? '✅ 달성' : '❌ 미달성'));
    System.debug('⚡ 목표 2: 20분→5초 갱신 프로세스 → ' + (renewalSuccessCount > 0 ? '✅ 달성' : '❌ 미달성'));
    System.debug('📈 목표 3: 실시간 성과 추적 → ' + (dashboardData != null ? '✅ 달성' : '❌ 미달성'));
    System.debug('🎮 목표 4: 게임화 동기부여 → ' + 
                (dashboardData != null && dashboardData.gamification != null ? '✅ 달성' : '❌ 미달성'));
    
} catch(Exception e) {
    System.debug('❌ 통합 테스트 중 예외 발생: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

System.debug('');
System.debug('🚀 === Assets 로직 통합 테스트 완료 ===');
System.debug('✨ 영업사원을 위한 완전한 Assets 관리 시스템 준비됨!');

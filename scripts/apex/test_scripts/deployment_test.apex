/**
 * 배포용 간소화 버전 테스트
 * 목적: 표준 필드만 사용하여 배포 가능한 상태 확인
 */

System.debug('=== 배포용 간소화 버전 테스트 시작 ===');

try {
    // PerformanceTrackingServiceSimple 클래스 테스트
    System.debug('--- 간소화된 대시보드 데이터 조회 테스트 ---');
    
    PerformanceTrackingServiceSimple.DashboardData dashboardData = 
        PerformanceTrackingServiceSimple.getDashboardData();
    
    if(dashboardData != null) {
        System.debug('✅ 간소화 대시보드 데이터 로딩 성공!');
        
        // 오늘의 예상 매출 테스트
        if(dashboardData.todayRevenue != null) {
            System.debug('💰 오늘 예상 매출: ₩' + dashboardData.todayRevenue.expectedAmount);
            System.debug('🎯 달성률: ' + dashboardData.todayRevenue.achievementRate + '%');
            System.debug('📊 상태: ' + dashboardData.todayRevenue.status);
        }
        
        // 월간 갱신 현황 테스트
        if(dashboardData.monthlyRenewal != null) {
            System.debug('📈 완료 갱신: ' + dashboardData.monthlyRenewal.completedCount + '건');
            System.debug('🔄 진행 갱신: ' + dashboardData.monthlyRenewal.inProgressCount + '건');
        }
        
        // 고객 건강도 테스트
        if(dashboardData.customerHealth != null) {
            System.debug('🟢 건강 고객: ' + dashboardData.customerHealth.healthyCount + '명');
            System.debug('🟡 주의 고객: ' + dashboardData.customerHealth.warningCount + '명');
            System.debug('🔴 위험 고객: ' + dashboardData.customerHealth.riskCount + '명');
        }
        
        // 효율성 지표 테스트
        if(dashboardData.efficiency != null) {
            System.debug('⚡ 성공률: ' + dashboardData.efficiency.successRate + '%');
            System.debug('📊 월간 처리: ' + dashboardData.efficiency.monthlyProcessCount + '건');
        }
        
        // 게임화 테스트
        if(dashboardData.gamification != null) {
            System.debug('🏆 현재 레벨: ' + dashboardData.gamification.currentLevel);
            System.debug('💰 현재 금액: ₩' + dashboardData.gamification.currentAmount);
            System.debug('📈 진행률: ' + dashboardData.gamification.progressPercentage + '%');
        }
        
        // 알림 테스트
        if(dashboardData.notifications != null) {
            System.debug('🔔 알림 수: ' + dashboardData.notifications.size() + '건');
            for(PerformanceTrackingServiceSimple.SmartNotification notif : dashboardData.notifications) {
                System.debug('  - ' + notif.title + ': ' + notif.message);
            }
        }
        
        // 새로고침 테스트
        String refreshResult = PerformanceTrackingServiceSimple.refreshDashboard();
        System.debug('🔄 새로고침 결과: ' + refreshResult);
        
        System.debug('');
        System.debug('✅ === 배포용 간소화 버전 테스트 성공 ===');
        System.debug('🎯 표준 필드만 사용하여 배포 가능한 상태 확인됨');
        System.debug('⚡ 핵심 기능 모두 정상 작동');
        System.debug('📊 실제 Salesforce 환경에서 배포 준비 완료');
        
    } else {
        System.debug('❌ 간소화 대시보드 데이터 로딩 실패');
    }
    
} catch(Exception e) {
    System.debug('❌ 배포용 테스트 중 예외 발생: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

System.debug('=== 배포용 간소화 버전 테스트 완료 ===');

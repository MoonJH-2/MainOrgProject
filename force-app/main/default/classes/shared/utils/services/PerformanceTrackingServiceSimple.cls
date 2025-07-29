/**
 * Logic 3: Performance Tracking Dashboard Service (배포용 간소화 버전)
 * 목적: 영업사원의 실시간 성과 추적 및 대시보드 데이터 제공
 */
public with sharing class PerformanceTrackingServiceSimple {
    
    /**
     * 대시보드 메인 데이터 래퍼 클래스
     */
    public class DashboardData {
        @AuraEnabled public TodayRevenue todayRevenue;
        @AuraEnabled public MonthlyRenewal monthlyRenewal;
        @AuraEnabled public CustomerHealth customerHealth;
        @AuraEnabled public EfficiencyMetrics efficiency;
        @AuraEnabled public GameificationData gamification;
        @AuraEnabled public List<SmartNotification> notifications;
        @AuraEnabled public DateTime lastUpdated;
    }
    
    /**
     * 1. 오늘의 예상 매출 데이터
     */
    public class TodayRevenue {
        @AuraEnabled public Decimal expectedAmount;
        @AuraEnabled public Decimal targetAmount;
        @AuraEnabled public Decimal achievementRate;
        @AuraEnabled public Integer priorityCustomers;
        @AuraEnabled public String status; // 'on-track', 'behind', 'ahead'
    }
    
    /**
     * 2. 이번 달 갱신 현황 데이터
     */  
    public class MonthlyRenewal {
        @AuraEnabled public Integer completedCount;
        @AuraEnabled public Decimal completedAmount;
        @AuraEnabled public Integer inProgressCount;
        @AuraEnabled public Decimal inProgressAmount;
        @AuraEnabled public Decimal totalExpectedAmount;
        @AuraEnabled public Decimal monthlyTarget;
    }
    
    /**
     * 3. 고객 건강도 분포 데이터
     */
    public class CustomerHealth {
        @AuraEnabled public Integer healthyCount;
        @AuraEnabled public Integer warningCount;
        @AuraEnabled public Integer riskCount;
        @AuraEnabled public Decimal healthyPercentage;
        @AuraEnabled public Decimal warningPercentage;
        @AuraEnabled public Decimal riskPercentage;
    }
    
    /**
     * 4. 업무 효율성 지표 데이터
     */
    public class EfficiencyMetrics {
        @AuraEnabled public Decimal avgProcessingTime; // 초 단위
        @AuraEnabled public Decimal successRate; // 퍼센트
        @AuraEnabled public Integer monthlyProcessCount;
        @AuraEnabled public Decimal timeReduction; // Logic 2로 인한 시간 절약
    }
    
    /**
     * 게임화 데이터 (동기부여)
     */
    public class GameificationData {
        @AuraEnabled public String currentLevel;
        @AuraEnabled public Decimal currentAmount;
        @AuraEnabled public Decimal nextLevelAmount;
        @AuraEnabled public Decimal progressPercentage;
        @AuraEnabled public String levelIcon;
        @AuraEnabled public String encouragementMessage;
    }
    
    /**
     * 스마트 알림 데이터
     */
    public class SmartNotification {
        @AuraEnabled public String id;
        @AuraEnabled public String type; // 'renewal', 'target', 'opportunity'
        @AuraEnabled public String title;
        @AuraEnabled public String message;
        @AuraEnabled public String priority; // 'high', 'medium', 'low'
        @AuraEnabled public String icon;
        @AuraEnabled public DateTime createdDate;
    }
    
    /**
     * 메인 대시보드 데이터 조회 메소드 (간소화 버전)
     */
    @AuraEnabled(cacheable=true)
    public static DashboardData getDashboardData() {
        try {
            DashboardData dashboard = new DashboardData();
            
            dashboard.todayRevenue = calculateTodayRevenue();
            dashboard.monthlyRenewal = calculateMonthlyRenewal();
            dashboard.customerHealth = calculateCustomerHealth();
            dashboard.efficiency = calculateEfficiencyMetrics();
            dashboard.gamification = calculateGameificationData(dashboard.monthlyRenewal.completedAmount);
            dashboard.notifications = generateSmartNotifications();
            dashboard.lastUpdated = DateTime.now();
            
            return dashboard;
            
        } catch (Exception e) {
            System.debug('Performance Dashboard Error: ' + e.getMessage());
            throw new AuraHandledException('대시보드 데이터 로딩 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 1. 오늘의 예상 매출 계산 (표준 필드만 사용)
     */
    private static TodayRevenue calculateTodayRevenue() {
        TodayRevenue today = new TodayRevenue();
        
        // 고액 자산 우선으로 예상 매출 계산
        List<Asset> priorityAssets = [
            SELECT Id, Name, Price, Quantity, UsageEndDate, 
                   AccountId, Account.Name, Status
            FROM Asset 
            WHERE Price >= 1000000 
            AND UsageEndDate <= :Date.today().addDays(90)
            AND Status = 'Installed'
            ORDER BY Price DESC
            LIMIT 10
        ];
        
        Decimal totalExpected = 0;
        for(Asset asset : priorityAssets) {
            Decimal renewalProb = 0.8; // 기본 80% 갱신 확률
            Decimal assetValue = (asset.Price != null) ? asset.Price * asset.Quantity : 0;
            totalExpected += assetValue * renewalProb;
        }
        
        today.expectedAmount = totalExpected;
        today.targetAmount = 50000000; // 일일 목표 5천만원
        today.achievementRate = (today.targetAmount > 0) ? 
            (today.expectedAmount / today.targetAmount * 100) : 0;
        today.priorityCustomers = priorityAssets.size();
        
        // 상태 결정
        if(today.achievementRate >= 100) {
            today.status = 'ahead';
        } else if(today.achievementRate >= 80) {
            today.status = 'on-track';
        } else {
            today.status = 'behind';
        }
        
        return today;
    }
    
    /**
     * 2. 이번 달 갱신 현황 계산
     */
    private static MonthlyRenewal calculateMonthlyRenewal() {
        MonthlyRenewal monthly = new MonthlyRenewal();
        
        Date monthStart = Date.today().toStartOfMonth();
        Date monthEnd = monthStart.addMonths(1).addDays(-1);
        
        // 완료된 갱신 (Won Opportunities)
        List<Opportunity> completedOpps = [
            SELECT Id, Amount, StageName, CloseDate
            FROM Opportunity 
            WHERE StageName = 'Closed Won'
            AND CloseDate >= :monthStart 
            AND CloseDate <= :monthEnd
            LIMIT 1000
        ];
        
        monthly.completedCount = completedOpps.size();
        monthly.completedAmount = 0;
        for(Opportunity opp : completedOpps) {
            monthly.completedAmount += (opp.Amount != null) ? opp.Amount : 0;
        }
        
        // 진행 중인 갱신
        List<Opportunity> inProgressOpps = [
            SELECT Id, Amount, StageName, CloseDate
            FROM Opportunity 
            WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
            AND CloseDate >= :monthStart 
            AND CloseDate <= :monthEnd
            LIMIT 1000
        ];
        
        monthly.inProgressCount = inProgressOpps.size();
        monthly.inProgressAmount = 0;
        for(Opportunity opp : inProgressOpps) {
            monthly.inProgressAmount += (opp.Amount != null) ? opp.Amount : 0;
        }
        
        monthly.totalExpectedAmount = monthly.completedAmount + monthly.inProgressAmount;
        monthly.monthlyTarget = 300000000; // 월 목표 3억원
        
        return monthly;
    }
    
    /**
     * 3. 고객 건강도 분포 계산 (간소화)
     */
    private static CustomerHealth calculateCustomerHealth() {
        CustomerHealth health = new CustomerHealth();
        
        // Case 수로 고객 건강도 분류
        List<Account> allAccounts = [
            SELECT Id, Name, 
                   (SELECT Id FROM Cases WHERE Status != 'Closed')
            FROM Account 
            WHERE Id IN (
                SELECT AccountId FROM Asset WHERE Status = 'Installed'
            )
            LIMIT 1000
        ];
        
        Integer healthyCount = 0;
        Integer warningCount = 0;
        Integer riskCount = 0;
        
        for(Account acc : allAccounts) {
            Integer caseCount = acc.Cases.size();
            
            if(caseCount == 0) {
                healthyCount++;
            } else if(caseCount <= 2) {
                warningCount++;
            } else {
                riskCount++;
            }
        }
        
        Integer totalCustomers = allAccounts.size();
        
        health.healthyCount = healthyCount;
        health.warningCount = warningCount;
        health.riskCount = riskCount;
        
        if(totalCustomers > 0) {
            health.healthyPercentage = (Decimal)healthyCount / totalCustomers * 100;
            health.warningPercentage = (Decimal)warningCount / totalCustomers * 100;
            health.riskPercentage = (Decimal)riskCount / totalCustomers * 100;
        } else {
            health.healthyPercentage = 0;
            health.warningPercentage = 0;
            health.riskPercentage = 0;
        }
        
        return health;
    }
    
    /**
     * 4. 업무 효율성 지표 계산 (간소화)
     */
    private static EfficiencyMetrics calculateEfficiencyMetrics() {
        EfficiencyMetrics metrics = new EfficiencyMetrics();
        
        Date monthStart = Date.today().toStartOfMonth();
        
        // 이번 달 생성된 Opportunity 조회
        List<Opportunity> monthlyOpps = [
            SELECT Id, Amount, StageName, CreatedDate, LastModifiedDate
            FROM Opportunity 
            WHERE CreatedDate >= :monthStart
            LIMIT 1000
        ];
        
        metrics.monthlyProcessCount = monthlyOpps.size();
        
        // 성공률 계산
        Integer successCount = 0;
        Long totalProcessingTime = 0;
        
        for(Opportunity opp : monthlyOpps) {
            if(opp.StageName == 'Closed Won') {
                successCount++;
            }
            
            // 처리 시간 계산 (생성 ~ 최종 수정)
            Long processingTime = opp.LastModifiedDate.getTime() - opp.CreatedDate.getTime();
            totalProcessingTime += processingTime;
        }
        
        if(monthlyOpps.size() > 0) {
            metrics.successRate = (Decimal)successCount / monthlyOpps.size() * 100;
            metrics.avgProcessingTime = totalProcessingTime / monthlyOpps.size() / 1000; // 초 단위
        } else {
            metrics.successRate = 0;
            metrics.avgProcessingTime = 0;
        }
        
        // Logic 2로 인한 시간 절약 (기존 20분 → 5초)
        metrics.timeReduction = (20 * 60 - 5) * monthlyOpps.size(); // 초 단위
        
        return metrics;
    }
    
    /**
     * 게임화 데이터 계산
     */
    private static GameificationData calculateGameificationData(Decimal currentAmount) {
        GameificationData game = new GameificationData();
        
        game.currentAmount = (currentAmount != null) ? currentAmount : 0;
        
        // 현재 레벨 및 다음 목표 계산
        if(game.currentAmount >= 100000000) { // 1억원
            game.currentLevel = 'PLATINUM';
            game.nextLevelAmount = 100000000;
            game.progressPercentage = 100;
            game.encouragementMessage = '전설급 성과! 최고 레벨 달성!';
            game.levelIcon = '💎';
        } else if(game.currentAmount >= 50000000) { // 5천만원
            game.currentLevel = 'GOLD';
            game.nextLevelAmount = 100000000;
            game.progressPercentage = (game.currentAmount - 50000000) / 50000000 * 100;
            game.encouragementMessage = '골드 레벨! 플래티넘까지 조금 남았습니다!';
            game.levelIcon = '🥇';
        } else if(game.currentAmount >= 30000000) { // 3천만원
            game.currentLevel = 'SILVER';
            game.nextLevelAmount = 50000000;
            game.progressPercentage = (game.currentAmount - 30000000) / 20000000 * 100;
            game.encouragementMessage = '실버 레벨! 골드까지 힘내세요!';
            game.levelIcon = '🥈';
        } else {
            game.currentLevel = 'BRONZE';
            game.nextLevelAmount = 30000000;
            game.progressPercentage = game.currentAmount / 30000000 * 100;
            game.encouragementMessage = '시작이 좋습니다! 실버까지 화이팅!';
            game.levelIcon = '🥉';
        }
        
        return game;
    }
    
    /**
     * 스마트 알림 생성 (간소화)
     */
    private static List<SmartNotification> generateSmartNotifications() {
        List<SmartNotification> notifications = new List<SmartNotification>();
        
        // 갱신 임박 알림
        List<Asset> upcomingRenewals = [
            SELECT Id, Name, AccountId, Account.Name, UsageEndDate, Price
            FROM Asset 
            WHERE UsageEndDate <= :Date.today().addDays(14)
            AND UsageEndDate >= :Date.today()
            AND Status = 'Installed'
            ORDER BY UsageEndDate ASC
            LIMIT 3
        ];
        
        for(Asset asset : upcomingRenewals) {
            SmartNotification notification = new SmartNotification();
            notification.id = 'renewal_' + asset.Id;
            notification.type = 'renewal';
            notification.title = '갱신 임박 알림';
            notification.message = asset.Account.Name + ' - ' + asset.Name + ' 갱신이 ' + 
                                 asset.UsageEndDate.daysBetween(Date.today()) + '일 남았습니다';
            notification.priority = 'high';
            notification.icon = '⏰';
            notification.createdDate = DateTime.now();
            notifications.add(notification);
        }
        
        // 고액 기회 발견 알림
        List<Asset> highValueOpportunities = [
            SELECT Id, Name, AccountId, Account.Name, Price, Quantity
            FROM Asset 
            WHERE Price >= 5000000
            AND Status = 'Installed'
            AND UsageEndDate <= :Date.today().addDays(180)
            ORDER BY Price DESC
            LIMIT 2
        ];
        
        for(Asset asset : highValueOpportunities) {
            SmartNotification oppNotification = new SmartNotification();
            oppNotification.id = 'opportunity_' + asset.Id;
            oppNotification.type = 'opportunity';
            oppNotification.title = '고액 갱신 기회';
            oppNotification.message = '고객 ' + asset.Account.Name + '의 ' + 
                String.valueOf((asset.Price * asset.Quantity)/10000) + '만원 갱신 기회가 발견되었습니다';
            oppNotification.priority = 'high';
            oppNotification.icon = '💰';
            oppNotification.createdDate = DateTime.now();
            notifications.add(oppNotification);
        }
        
        return notifications;
    }
    
    /**
     * 실시간 데이터 새로고침
     */
    @AuraEnabled
    public static String refreshDashboard() {
        try {
            DateTime refreshTime = DateTime.now();
            return 'Dashboard refreshed at: ' + refreshTime.format('yyyy-MM-dd HH:mm:ss');
        } catch (Exception e) {
            throw new AuraHandledException('대시보드 새로고침 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
}

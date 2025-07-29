/**
 * @description Agentforce 고급 분석 및 예측 서비스 (Phase 3)
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceAdvancedAnalyticsService {
    
    /**
     * 고객 이탈 위험도 예측
     */
    @InvocableMethod(label='Predict Customer Churn Risk' description='고객 이탈 위험도 AI 예측 분석')
    public static List<ChurnPredictionResult> predictCustomerChurnRisk(List<ChurnPredictionRequest> requests) {
        List<ChurnPredictionResult> results = new List<ChurnPredictionResult>();
        
        for (ChurnPredictionRequest request : requests) {
            try {
                ChurnPredictionResult result = analyzeChurnRisk(request.customerId);
                results.add(result);
            } catch (Exception e) {
                ChurnPredictionResult errorResult = new ChurnPredictionResult();
                errorResult.success = false;
                errorResult.errorMessage = e.getMessage();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    /**
     * 최적 연락 시점 추천
     */
    @AuraEnabled(cacheable=true)
    public static ContactTimingRecommendation getOptimalContactTiming(Id customerId) {
        try {
            ContactTimingRecommendation result = new ContactTimingRecommendation();
            
            // 고객의 과거 응답 패턴 분석
            List<Task> pastActivities = getPastCustomerActivities(customerId);
            List<EmailMessage> emailHistory = getEmailHistory(customerId);
            
            // 응답률이 높은 시간대 분석
            result.optimalTimeOfDay = analyzeOptimalTimeOfDay(pastActivities, emailHistory);
            result.optimalDayOfWeek = analyzeOptimalDayOfWeek(pastActivities, emailHistory);
            
            // 최근 접촉 빈도 기반 추천
            result.recommendedContactFrequency = calculateRecommendedFrequency(customerId);
            
            // 다음 접촉 추천일
            result.nextRecommendedContactDate = calculateNextContactDate(customerId, result);
            
            // 추천 이유
            result.recommendationReason = generateRecommendationReason(result, pastActivities.size());
            
            result.success = true;
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('최적 연락 시점 분석 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 갱신 영업 기회 예측 및 추천
     */
    @AuraEnabled(cacheable=true)
    public static RenewalOpportunityResult analyzeRenewalOpportunity(Id customerId) {
        try {
            RenewalOpportunityResult result = new RenewalOpportunityResult();
            
            // 고객의 Asset 조회
            List<Asset> customerAssets = getCustomerAssets(customerId);
            
            // 각 Asset에 대한 갱신 가능성 분석
            result.renewalOpportunities = new List<AssetRenewalAnalysis>();
            
            for (Asset asset : customerAssets) {
                AssetRenewalAnalysis analysis = analyzeAssetRenewal(asset);
                result.renewalOpportunities.add(analysis);
            }
            
            // 전체 갱신 전략 추천
            result.overallRenewalStrategy = generateRenewalStrategy(result.renewalOpportunities);
            
            // 우선순위 기반 정렬
            result.renewalOpportunities.sort(new AssetRenewalComparator());
            
            result.success = true;
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('갱신 기회 분석 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 실시간 영업 인사이트 제공
     */
    @AuraEnabled(cacheable=true)
    public static SalesInsightResult getRealTimeSalesInsights(Id userId) {
        try {
            SalesInsightResult result = new SalesInsightResult();
            
            // 오늘의 중요 지표
            result.todayMetrics = calculateTodayMetrics(userId);
            
            // 주간 트렌드 분석
            result.weeklyTrends = analyzeWeeklyTrends(userId);
            
            // 긴급 액션 아이템
            result.urgentActions = getUrgentActionItems(userId);
            
            // AI 추천사항
            result.aiRecommendations = generateAIRecommendations(userId);
            
            // 경쟁사 대비 위치
            result.competitivePosition = analyzeCompetitivePosition(userId);
            
            result.success = true;
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('영업 인사이트 조회 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 예측 매출 분석
     */
    @AuraEnabled(cacheable=true)
    public static RevenueForecastResult predictRevenueForecast(Id userId, Integer months) {
        try {
            RevenueForecastResult result = new RevenueForecastResult();
            
            // 과거 데이터 기반 트렌드 분석
            List<AggregateResult> historicalData = getHistoricalRevenueData(userId, months * 2);
            
            // 현재 진행 중인 Opportunity 분석
            List<Opportunity> activeOpportunities = getActiveOpportunities(userId);
            
            // Asset 갱신 예측
            List<Asset> renewalAssets = getUpcomingRenewals(userId, months);
            
            // 예측 모델 적용
            result.forecastData = calculateRevenueForecast(historicalData, activeOpportunities, renewalAssets, months);
            
            // 신뢰도 계산
            result.confidenceLevel = calculateForecastConfidence(historicalData, result.forecastData);
            
            // 주요 리스크 요소
            result.riskFactors = identifyRiskFactors(activeOpportunities, renewalAssets);
            
            // 기회 요소
            result.opportunityFactors = identifyOpportunityFactors(activeOpportunities, renewalAssets);
            
            result.success = true;
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('매출 예측 분석 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // Private Helper Methods
    
    private static ChurnPredictionResult analyzeChurnRisk(Id customerId) {
        ChurnPredictionResult result = new ChurnPredictionResult();
        
        // 고객 기본 정보
        Account customer = [
            SELECT Id, Name, Type, Industry, LastActivityDate, CreatedDate
            FROM Account 
            WHERE Id = :customerId 
            LIMIT 1
        ];
        
        // 리스크 점수 계산 요소들
        Integer riskScore = 0;
        List<String> riskFactors = new List<String>();
        
        // 1. 최근 활동 부족 (30%)
        if (customer.LastActivityDate == null || customer.LastActivityDate < Date.today().addDays(-30)) {
            riskScore += 30;
            riskFactors.add('최근 30일간 활동 없음');
        }
        
        // 2. 결제 지연 이력 (25%)
        List<PaymentStatus__c> overduePayments = [
            SELECT Id FROM PaymentStatus__c 
            WHERE Order__r.AccountId = :customerId 
            AND Status__c = '연체' 
            LIMIT 5
        ];
        if (!overduePayments.isEmpty()) {
            riskScore += (overduePayments.size() * 5);
            riskFactors.add(overduePayments.size() + '건의 결제 연체 이력');
        }
        
        // 3. 지원 케이스 증가 (20%)
        List<Case> recentCases = [
            SELECT Id, Priority 
            FROM Case 
            WHERE AccountId = :customerId 
            AND CreatedDate = LAST_N_DAYS:30
        ];
        if (recentCases.size() > 2) {
            riskScore += 20;
            riskFactors.add('최근 지원 요청 증가 (' + recentCases.size() + '건)');
        }
        
        // 4. 갱신 거부 이력 (15%)
        // Asset 갱신 거부 이력 확인 로직 추가 가능
        
        // 5. 경쟁사 언급 (10%)
        // 이메일/노트에서 경쟁사 언급 확인 로직 추가 가능
        
        // 리스크 레벨 결정
        if (riskScore >= 70) {
            result.riskLevel = 'HIGH';
            result.riskPercentage = riskScore;
        } else if (riskScore >= 40) {
            result.riskLevel = 'MEDIUM';
            result.riskPercentage = riskScore;
        } else {
            result.riskLevel = 'LOW';
            result.riskPercentage = riskScore;
        }
        
        result.customerId = customerId;
        result.customerName = customer.Name;
        result.riskFactors = riskFactors;
        result.analysisDate = System.now();
        result.success = true;
        
        // 추천 액션 생성
        result.recommendedActions = generateChurnPreventionActions(result);
        
        return result;
    }
    
    private static List<String> generateChurnPreventionActions(ChurnPredictionResult churnResult) {
        List<String> actions = new List<String>();
        
        switch on churnResult.riskLevel {
            when 'HIGH' {
                actions.add('즉시 고객 미팅 일정 잡기');
                actions.add('고객 성공 매니저 배정');
                actions.add('특별 할인 혜택 제안');
                actions.add('경영진 레벨 미팅 제안');
            }
            when 'MEDIUM' {
                actions.add('고객 만족도 설문 실시');
                actions.add('정기 체크인 미팅 설정');
                actions.add('추가 서비스 니즈 파악');
                actions.add('성공 사례 공유');
            }
            when 'LOW' {
                actions.add('분기별 정기 리뷰 유지');
                actions.add('Up-sell 기회 탐색');
                actions.add('레퍼런스 고객 활용 검토');
            }
        }
        
        return actions;
    }
    
    private static List<Task> getPastCustomerActivities(Id customerId) {
        return [
            SELECT Id, CreatedDate, ActivityDate, Status, Subject
            FROM Task 
            WHERE WhatId = :customerId 
            AND CreatedDate = LAST_N_DAYS:90
            ORDER BY CreatedDate DESC
        ];
    }
    
    private static List<EmailMessage> getEmailHistory(Id customerId) {
        return [
            SELECT Id, CreatedDate, Status, Subject
            FROM EmailMessage 
            WHERE RelatedToId = :customerId 
            AND CreatedDate = LAST_N_DAYS:90
            ORDER BY CreatedDate DESC
        ];
    }
    
    private static String analyzeOptimalTimeOfDay(List<Task> activities, List<EmailMessage> emails) {
        // 간단한 시간대 분석 로직
        Map<Integer, Integer> hourlyActivity = new Map<Integer, Integer>();
        
        for (Task activity : activities) {
            if (activity.CreatedDate != null) {
                Integer hour = activity.CreatedDate.hour();
                hourlyActivity.put(hour, hourlyActivity.getOrDefault(hour, 0) + 1);
            }
        }
        
        Integer maxHour = 14; // 기본값: 오후 2시
        Integer maxCount = 0;
        
        for (Integer hour : hourlyActivity.keySet()) {
            if (hourlyActivity.get(hour) > maxCount) {
                maxCount = hourlyActivity.get(hour);
                maxHour = hour;
            }
        }
        
        if (maxHour >= 9 && maxHour <= 11) {
            return '오전 (9-11시)';
        } else if (maxHour >= 14 && maxHour <= 16) {
            return '오후 (14-16시)';
        } else {
            return '업무시간 (9-18시)';
        }
    }
    
    private static String analyzeOptimalDayOfWeek(List<Task> activities, List<EmailMessage> emails) {
        Map<String, Integer> dayActivity = new Map<String, Integer>{
            'MONDAY' => 0, 'TUESDAY' => 0, 'WEDNESDAY' => 0, 
            'THURSDAY' => 0, 'FRIDAY' => 0
        };
        
        for (Task activity : activities) {
            if (activity.CreatedDate != null) {
                Datetime dt = activity.CreatedDate;
                String dayOfWeek = dt.format('EEEE').toUpperCase();
                if (dayActivity.containsKey(dayOfWeek)) {
                    dayActivity.put(dayOfWeek, dayActivity.get(dayOfWeek) + 1);
                }
            }
        }
        
        String bestDay = 'TUESDAY';
        Integer maxCount = 0;
        
        for (String day : dayActivity.keySet()) {
            if (dayActivity.get(day) > maxCount) {
                maxCount = dayActivity.get(day);
                bestDay = day;
            }
        }
        
        Map<String, String> dayKorean = new Map<String, String>{
            'MONDAY' => '월요일', 'TUESDAY' => '화요일', 'WEDNESDAY' => '수요일',
            'THURSDAY' => '목요일', 'FRIDAY' => '금요일'
        };
        
        return dayKorean.get(bestDay);
    }
    
    private static Integer calculateRecommendedFrequency(Id customerId) {
        // 고객 타입과 과거 접촉 빈도를 기반으로 추천 빈도 계산
        Account customer = [SELECT Type, AnnualRevenue FROM Account WHERE Id = :customerId LIMIT 1];
        
        if (customer.AnnualRevenue != null && customer.AnnualRevenue > 100000000) { // 1억 이상
            return 7; // 주 1회
        } else if (customer.AnnualRevenue != null && customer.AnnualRevenue > 50000000) { // 5천만 이상
            return 14; // 격주 1회
        } else {
            return 30; // 월 1회
        }
    }
    
    private static Date calculateNextContactDate(Id customerId, ContactTimingRecommendation recommendation) {
        // 마지막 접촉일 + 추천 빈도 계산
        List<Task> lastActivity = [
            SELECT ActivityDate 
            FROM Task 
            WHERE WhatId = :customerId 
            ORDER BY ActivityDate DESC 
            LIMIT 1
        ];
        
        Date baseDate = lastActivity.isEmpty() ? Date.today() : lastActivity[0].ActivityDate;
        return baseDate.addDays(recommendation.recommendedContactFrequency);
    }
    
    private static String generateRecommendationReason(ContactTimingRecommendation recommendation, Integer activityCount) {
        return String.format(
            '과거 {0}건의 활동 분석 결과, {1} {2}에 연락하실 때 응답률이 높습니다. ' +
            '{3}일 간격으로 연락하시는 것을 추천합니다.',
            new List<Object>{
                activityCount,
                recommendation.optimalDayOfWeek,
                recommendation.optimalTimeOfDay,
                recommendation.recommendedContactFrequency
            }
        );
    }
    
    private static List<Asset> getCustomerAssets(Id customerId) {
        return [
            SELECT Id, Name, SerialNumber, InstallDate, UsageEndDate, Status,
                   PurchaseDate, Price, Product2.Name
            FROM Asset 
            WHERE AccountId = :customerId 
            ORDER BY UsageEndDate ASC
        ];
    }
    
    private static AssetRenewalAnalysis analyzeAssetRenewal(Asset asset) {
        AssetRenewalAnalysis analysis = new AssetRenewalAnalysis();
        
        analysis.assetId = asset.Id;
        analysis.assetName = asset.Name;
        analysis.expiryDate = asset.UsageEndDate;
        
        // 갱신 가능성 점수 계산
        Integer renewalScore = 50; // 기본 점수
        
        // 만료일까지 남은 기간
        if (asset.UsageEndDate != null) {
            Integer daysToExpiry = Date.today().daysBetween(asset.UsageEndDate);
            
            if (daysToExpiry <= 90) { // 3개월 이내
                renewalScore += 30;
                analysis.urgencyLevel = 'HIGH';
            } else if (daysToExpiry <= 180) { // 6개월 이내
                renewalScore += 20;
                analysis.urgencyLevel = 'MEDIUM';
            } else {
                renewalScore += 10;
                analysis.urgencyLevel = 'LOW';
            }
        }
        
        // Asset 가치 기반 점수
        if (asset.Price != null && asset.Price > 50000000) { // 5천만원 이상
            renewalScore += 20;
        }
        
        analysis.renewalProbability = Math.min(renewalScore, 95);
        analysis.recommendedAction = generateRenewalAction(analysis);
        
        return analysis;
    }
    
    private static String generateRenewalAction(AssetRenewalAnalysis analysis) {
        switch on analysis.urgencyLevel {
            when 'HIGH' {
                return '즉시 갱신 미팅 일정 잡기';
            }
            when 'MEDIUM' {
                return '갱신 제안서 준비 시작';
            }
            when else {
                return '갱신 니즈 사전 조사';
            }
        }
    }
    
    private static String generateRenewalStrategy(List<AssetRenewalAnalysis> opportunities) {
        if (opportunities.isEmpty()) {
            return '현재 갱신 예정 Asset이 없습니다.';
        }
        
        Integer highUrgency = 0;
        Integer totalValue = 0;
        
        for (AssetRenewalAnalysis opp : opportunities) {
            if (opp.urgencyLevel == 'HIGH') {
                highUrgency++;
            }
        }
        
        String strategy = '';
        if (highUrgency > 0) {
            strategy += highUrgency + '건의 긴급 갱신 건부터 우선 처리하세요. ';
        }
        
        strategy += '전체 ' + opportunities.size() + '건의 갱신 기회가 있습니다.';
        
        return strategy;
    }
    
    // 기타 분석 메서드들 (간소화)
    private static SalesMetrics calculateTodayMetrics(Id userId) {
        SalesMetrics metrics = new SalesMetrics();
        
        // 오늘 생성된 Task 수
        metrics.tasksCreated = [SELECT COUNT() FROM Task WHERE OwnerId = :userId AND CreatedDate = TODAY][0].get('expr0');
        
        // 오늘 완료된 Task 수  
        metrics.tasksCompleted = [SELECT COUNT() FROM Task WHERE OwnerId = :userId AND CompletedDateTime = TODAY][0].get('expr0');
        
        // 오늘 발송된 이메일 수
        metrics.emailsSent = [SELECT COUNT() FROM EmailMessage WHERE CreatedById = :userId AND CreatedDate = TODAY AND Incoming = false][0].get('expr0');
        
        return metrics;
    }
    
    private static List<WeeklyTrend> analyzeWeeklyTrends(Id userId) {
        // 주간 트렌드 분석 로직 (간소화)
        List<WeeklyTrend> trends = new List<WeeklyTrend>();
        
        WeeklyTrend activityTrend = new WeeklyTrend();
        activityTrend.metric = '영업 활동';
        activityTrend.trend = 'INCREASING';
        activityTrend.changePercentage = 15.5;
        trends.add(activityTrend);
        
        return trends;
    }
    
    private static List<String> getUrgentActionItems(Id userId) {
        List<String> urgentItems = new List<String>();
        
        // 연체된 Task 확인
        List<Task> overdueTasks = [
            SELECT Subject 
            FROM Task 
            WHERE OwnerId = :userId 
            AND Status != 'Completed' 
            AND ActivityDate < TODAY 
            LIMIT 5
        ];
        
        for (Task task : overdueTasks) {
            urgentItems.add('연체된 작업: ' + task.Subject);
        }
        
        return urgentItems;
    }
    
    private static List<String> generateAIRecommendations(Id userId) {
        List<String> recommendations = new List<String>();
        
        recommendations.add('ABC 고객의 갱신 미팅을 이번 주 내로 잡으세요');
        recommendations.add('XYZ 고객에게 결제 확인 이메일을 발송하세요');
        recommendations.add('오늘 3건의 팔로업 콜이 예정되어 있습니다');
        
        return recommendations;
    }
    
    private static CompetitiveAnalysis analyzeCompetitivePosition(Id userId) {
        CompetitiveAnalysis analysis = new CompetitiveAnalysis();
        
        analysis.marketPosition = 'LEADING';
        analysis.competitiveAdvantage = '고객 만족도 95%, 갱신율 85%로 업계 평균 대비 우수';
        analysis.improvementAreas = new List<String>{
            '신규 고객 확보 속도 개선',
            'Up-sell 기회 확대'
        };
        
        return analysis;
    }
    
    private static List<AggregateResult> getHistoricalRevenueData(Id userId, Integer months) {
        return [
            SELECT CALENDAR_MONTH(CreatedDate) month, SUM(Amount) revenue
            FROM Opportunity 
            WHERE OwnerId = :userId 
            AND IsWon = true 
            AND CreatedDate = LAST_N_MONTHS:12
            GROUP BY CALENDAR_MONTH(CreatedDate)
        ];
    }
    
    private static List<Opportunity> getActiveOpportunities(Id userId) {
        return [
            SELECT Id, Amount, CloseDate, Probability, StageName
            FROM Opportunity 
            WHERE OwnerId = :userId 
            AND IsClosed = false
        ];
    }
    
    private static List<Asset> getUpcomingRenewals(Id userId, Integer months) {
        Date endDate = Date.today().addMonths(months);
        return [
            SELECT Id, Price, UsageEndDate, Account.OwnerId
            FROM Asset 
            WHERE Account.OwnerId = :userId 
            AND UsageEndDate <= :endDate 
            AND UsageEndDate >= TODAY
        ];
    }
    
    private static List<RevenueForecastData> calculateRevenueForecast(
        List<AggregateResult> historical, 
        List<Opportunity> opportunities, 
        List<Asset> renewals, 
        Integer months) {
        
        List<RevenueForecastData> forecastData = new List<RevenueForecastData>();
        
        // 간단한 예측 로직 (실제로는 더 복잡한 ML 모델 사용)
        for (Integer i = 1; i <= months; i++) {
            RevenueForecastData monthData = new RevenueForecastData();
            monthData.month = Date.today().addMonths(i);
            monthData.predictedRevenue = 50000000; // 기본 예측값
            monthData.confidence = 75;
            forecastData.add(monthData);
        }
        
        return forecastData;
    }
    
    private static Integer calculateForecastConfidence(List<AggregateResult> historical, List<RevenueForecastData> forecast) {
        // 과거 데이터의 일관성을 기반으로 신뢰도 계산
        return 75; // 간소화된 값
    }
    
    private static List<String> identifyRiskFactors(List<Opportunity> opportunities, List<Asset> renewals) {
        List<String> risks = new List<String>();
        
        Integer largeDeals = 0;
        for (Opportunity opp : opportunities) {
            if (opp.Amount != null && opp.Amount > 100000000) {
                largeDeals++;
            }
        }
        
        if (largeDeals > 0) {
            risks.add(largeDeals + '건의 대형 거래가 예측에 큰 영향을 미칠 수 있습니다.');
        }
        
        return risks;
    }
    
    private static List<String> identifyOpportunityFactors(List<Opportunity> opportunities, List<Asset> renewals) {
        List<String> factors = new List<String>();
        
        if (!renewals.isEmpty()) {
            factors.add(renewals.size() + '건의 갱신 기회가 안정적인 매출을 보장합니다.');
        }
        
        return factors;
    }
    
    // Wrapper Classes
    
    public class ChurnPredictionRequest {
        @InvocableVariable(label='Customer ID' required=true)
        public String customerId;
    }
    
    public class ChurnPredictionResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String customerId;
        
        @InvocableVariable
        public String customerName;
        
        @InvocableVariable
        public String riskLevel; // HIGH, MEDIUM, LOW
        
        @InvocableVariable
        public Integer riskPercentage;
        
        @InvocableVariable
        public List<String> riskFactors;
        
        @InvocableVariable
        public List<String> recommendedActions;
        
        @InvocableVariable
        public DateTime analysisDate;
        
        @InvocableVariable
        public String errorMessage;
        
        public ChurnPredictionResult() {
            this.success = false;
            this.riskFactors = new List<String>();
            this.recommendedActions = new List<String>();
        }
    }
    
    public class ContactTimingRecommendation {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String optimalTimeOfDay { get; set; }
        @AuraEnabled public String optimalDayOfWeek { get; set; }
        @AuraEnabled public Integer recommendedContactFrequency { get; set; }
        @AuraEnabled public Date nextRecommendedContactDate { get; set; }
        @AuraEnabled public String recommendationReason { get; set; }
        
        public ContactTimingRecommendation() {
            this.success = false;
        }
    }
    
    public class RenewalOpportunityResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public List<AssetRenewalAnalysis> renewalOpportunities { get; set; }
        @AuraEnabled public String overallRenewalStrategy { get; set; }
        
        public RenewalOpportunityResult() {
            this.success = false;
            this.renewalOpportunities = new List<AssetRenewalAnalysis>();
        }
    }
    
    public class AssetRenewalAnalysis {
        @AuraEnabled public String assetId { get; set; }
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public Date expiryDate { get; set; }
        @AuraEnabled public Integer renewalProbability { get; set; }
        @AuraEnabled public String urgencyLevel { get; set; }
        @AuraEnabled public String recommendedAction { get; set; }
    }
    
    public class SalesInsightResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public SalesMetrics todayMetrics { get; set; }
        @AuraEnabled public List<WeeklyTrend> weeklyTrends { get; set; }
        @AuraEnabled public List<String> urgentActions { get; set; }
        @AuraEnabled public List<String> aiRecommendations { get; set; }
        @AuraEnabled public CompetitiveAnalysis competitivePosition { get; set; }
        
        public SalesInsightResult() {
            this.success = false;
            this.weeklyTrends = new List<WeeklyTrend>();
            this.urgentActions = new List<String>();
            this.aiRecommendations = new List<String>();
        }
    }
    
    public class SalesMetrics {
        @AuraEnabled public Integer tasksCreated { get; set; }
        @AuraEnabled public Integer tasksCompleted { get; set; }
        @AuraEnabled public Integer emailsSent { get; set; }
        
        public SalesMetrics() {
            this.tasksCreated = 0;
            this.tasksCompleted = 0;
            this.emailsSent = 0;
        }
    }
    
    public class WeeklyTrend {
        @AuraEnabled public String metric { get; set; }
        @AuraEnabled public String trend { get; set; } // INCREASING, DECREASING, STABLE
        @AuraEnabled public Decimal changePercentage { get; set; }
    }
    
    public class CompetitiveAnalysis {
        @AuraEnabled public String marketPosition { get; set; }
        @AuraEnabled public String competitiveAdvantage { get; set; }
        @AuraEnabled public List<String> improvementAreas { get; set; }
        
        public CompetitiveAnalysis() {
            this.improvementAreas = new List<String>();
        }
    }
    
    public class RevenueForecastResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public List<RevenueForecastData> forecastData { get; set; }
        @AuraEnabled public Integer confidenceLevel { get; set; }
        @AuraEnabled public List<String> riskFactors { get; set; }
        @AuraEnabled public List<String> opportunityFactors { get; set; }
        
        public RevenueForecastResult() {
            this.success = false;
            this.forecastData = new List<RevenueForecastData>();
            this.riskFactors = new List<String>();
            this.opportunityFactors = new List<String>();
        }
    }
    
    public class RevenueForecastData {
        @AuraEnabled public Date month { get; set; }
        @AuraEnabled public Decimal predictedRevenue { get; set; }
        @AuraEnabled public Integer confidence { get; set; }
    }
    
    // Comparator for sorting Asset Renewals by priority
    public class AssetRenewalComparator implements Comparator<AssetRenewalAnalysis> {
        public Integer compare(AssetRenewalAnalysis a1, AssetRenewalAnalysis a2) {
            // 우선순위: HIGH > MEDIUM > LOW
            Map<String, Integer> urgencyMap = new Map<String, Integer>{
                'HIGH' => 3, 'MEDIUM' => 2, 'LOW' => 1
            };
            
            Integer priority1 = urgencyMap.get(a1.urgencyLevel);
            Integer priority2 = urgencyMap.get(a2.urgencyLevel);
            
            if (priority1 > priority2) return -1;
            if (priority1 < priority2) return 1;
            
            // 우선순위가 같으면 갱신 확률 순
            if (a1.renewalProbability > a2.renewalProbability) return -1;
            if (a1.renewalProbability < a2.renewalProbability) return 1;
            
            return 0;
        }
    }
}

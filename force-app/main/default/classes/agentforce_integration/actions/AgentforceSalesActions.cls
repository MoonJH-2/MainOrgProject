/**
 * @description Agentforce Sales Agent용 Custom Apex Actions
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceSalesActions {
    
    /**
     * 영업사원 성과 요약 조회
     */
    @InvocableMethod(label='Get Sales Performance Summary' description='영업사원의 종합 성과 지표를 조회합니다')
    public static List<SalesPerformanceResult> getSalesPerformanceSummary(List<SalesPerformanceRequest> requests) {
        List<SalesPerformanceResult> results = new List<SalesPerformanceResult>();
        
        for(SalesPerformanceRequest request : requests) {
            SalesPerformanceResult result = new SalesPerformanceResult();
            
            try {
                // 영업사원의 Order 성과 분석
                List<Order> userOrders = [
                    SELECT Id, Status, TotalAmount, EffectiveDate, AccountId, Account.Name
                    FROM Order 
                    WHERE OwnerId = :request.userId
                    AND EffectiveDate >= LAST_N_DAYS:90
                ];
                
                result.totalOrders = userOrders.size();
                result.successfulOrders = 0;
                result.totalAmount = 0;
                
                for(Order ord : userOrders) {
                    if(ord.Status == 'Activated') {
                        result.successfulOrders++;
                    }
                    if(ord.TotalAmount != null) {
                        result.totalAmount += ord.TotalAmount;
                    }
                }
                
                // 성공률 계산
                if(result.totalOrders > 0) {
                    result.successRate = (result.successfulOrders * 100) / result.totalOrders;
                } else {
                    result.successRate = 0;
                }
                
                // Asset 갱신 성과
                List<Asset> userAssets = [
                    SELECT Id, Status, Account.OwnerId
                    FROM Asset 
                    WHERE Account.OwnerId = :request.userId
                    AND Status = 'Installed'
                ];
                
                result.activeAssets = userAssets.size();
                
                // 성과 메시지 생성
                result.performanceSummary = generatePerformanceSummary(result);
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = '성과 조회 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * Asset 갱신 확률 예측
     */
    @InvocableMethod(label='Predict Asset Renewal' description='Einstein AI 기반 Asset 갱신 확률을 예측합니다')
    public static List<AssetRenewalResult> predictAssetRenewal(List<AssetRenewalRequest> requests) {
        List<AssetRenewalResult> results = new List<AssetRenewalResult>();
        
        for(AssetRenewalRequest request : requests) {
            AssetRenewalResult result = new AssetRenewalResult();
            
            try {
                // Asset 정보 조회
                Asset asset = [
                    SELECT Id, Name, Status, InstallDate, UsageEndDate, 
                           Account.Id, Account.Name, Account.Industry
                    FROM Asset 
                    WHERE Id = :request.assetId 
                    LIMIT 1
                ];
                
                // 갱신 확률 계산 (간단한 룰 기반)
                Integer daysSinceInstall = asset.InstallDate != null ? 
                    Date.today().daysBetween(asset.InstallDate) : 0;
                Integer daysToExpiry = asset.UsageEndDate != null ? 
                    Date.today().daysBetween(asset.UsageEndDate) : 365;
                
                // 업종별 가중치
                Decimal industryWeight = getIndustryWeight(asset.Account.Industry);
                
                // 갱신 확률 계산
                if(daysToExpiry <= 30) {
                    result.renewalProbability = 85 + industryWeight;
                } else if(daysToExpiry <= 90) {
                    result.renewalProbability = 70 + industryWeight;
                } else {
                    result.renewalProbability = 60 + industryWeight;
                }
                
                // 최대 95%로 제한
                if(result.renewalProbability > 95) {
                    result.renewalProbability = 95;
                }
                
                result.assetName = asset.Name;
                result.accountName = asset.Account.Name;
                result.daysToExpiry = daysToExpiry;
                result.recommendedActions = generateRenewalActions(result.renewalProbability, daysToExpiry);
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = 'Asset 조회 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * 고객 인사이트 생성
     */
    @InvocableMethod(label='Generate Customer Insights' description='고객별 상세 분석 및 액션 추천을 제공합니다')
    public static List<CustomerInsightResult> generateCustomerInsights(List<CustomerInsightRequest> requests) {
        List<CustomerInsightResult> results = new List<CustomerInsightResult>();
        
        for(CustomerInsightRequest request : requests) {
            CustomerInsightResult result = new CustomerInsightResult();
            
            try {
                // Account 정보 조회
                Account account = [
                    SELECT Id, Name, Industry, Type, AnnualRevenue, 
                           NumberOfEmployees, OwnerId, Owner.Name
                    FROM Account 
                    WHERE Id = :request.accountId 
                    LIMIT 1
                ];
                
                // Order 이력 조회
                List<Order> accountOrders = [
                    SELECT Id, Status, TotalAmount, EffectiveDate
                    FROM Order 
                    WHERE AccountId = :request.accountId
                    ORDER BY EffectiveDate DESC
                    LIMIT 10
                ];
                
                // Asset 현황 조회
                List<Asset> accountAssets = [
                    SELECT Id, Name, Status, InstallDate, UsageEndDate
                    FROM Asset 
                    WHERE AccountId = :request.accountId
                    AND Status = 'Installed'
                ];
                
                result.accountName = account.Name;
                result.industry = account.Industry;
                result.totalOrders = accountOrders.size();
                result.activeAssets = accountAssets.size();
                result.accountOwner = account.Owner.Name;
                
                // 고객 점수 계산
                result.customerScore = calculateCustomerScore(account, accountOrders, accountAssets);
                
                // 인사이트 및 추천 액션 생성
                result.insights = generateCustomerInsights(account, accountOrders, accountAssets);
                result.recommendedActions = generateCustomerActions(result.customerScore, accountAssets);
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = '고객 분석 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Helper Methods
    private static String generatePerformanceSummary(SalesPerformanceResult result) {
        String summary = '📊 성과 요약\n';
        summary += '• 총 주문: ' + result.totalOrders + '개\n';
        summary += '• 성공률: ' + result.successRate + '%\n';
        summary += '• 총 금액: ₩' + String.valueOf(result.totalAmount.setScale(0)) + '\n';
        summary += '• 활성 Asset: ' + result.activeAssets + '개\n';
        
        if(result.successRate >= 90) {
            summary += '🏆 우수한 성과입니다!';
        } else if(result.successRate >= 70) {
            summary += '👍 양호한 성과입니다.';
        } else {
            summary += '💪 개선이 필요합니다.';
        }
        
        return summary;
    }
    
    private static Decimal getIndustryWeight(String industry) {
        Map<String, Decimal> industryWeights = new Map<String, Decimal>{
            'Technology' => 10,
            'Manufacturing' => 8,
            'Financial Services' => 12,
            'Healthcare' => 9,
            'Education' => 7
        };
        
        return industryWeights.get(industry) != null ? industryWeights.get(industry) : 5;
    }
    
    private static String generateRenewalActions(Decimal probability, Integer daysToExpiry) {
        String actions = '🎯 추천 액션:\n';
        
        if(probability >= 80) {
            actions += '• 갱신 계약서 준비\n';
            actions += '• 고객 미팅 스케줄링\n';
            actions += '• 업그레이드 옵션 제안';
        } else if(probability >= 60) {
            actions += '• 고객 만족도 조사\n';
            actions += '• 추가 가치 제안 준비\n';
            actions += '• 경쟁사 분석 실시';
        } else {
            actions += '• 관계 개선 전략 수립\n';
            actions += '• 할인 혜택 검토\n';
            actions += '• 대안 솔루션 탐색';
        }
        
        return actions;
    }
    
    private static Integer calculateCustomerScore(Account account, List<Order> orders, List<Asset> assets) {
        Integer score = 50; // Base score
        
        // Order 이력 점수
        score += orders.size() * 5;
        
        // Asset 보유 점수
        score += assets.size() * 8;
        
        // 업종별 가중치
        if(account.Industry == 'Technology') score += 10;
        if(account.Industry == 'Manufacturing') score += 8;
        
        // 연매출 가중치
        if(account.AnnualRevenue != null && account.AnnualRevenue > 1000000) {
            score += 15;
        }
        
        return Math.min(score, 100); // 최대 100점
    }
    
    private static String generateCustomerInsights(Account account, List<Order> orders, List<Asset> assets) {
        String insights = '🔍 고객 인사이트\n';
        insights += '• 업종: ' + account.Industry + '\n';
        insights += '• 주문 이력: ' + orders.size() + '건\n';
        insights += '• 보유 Asset: ' + assets.size() + '개\n';
        
        if(orders.size() > 5) {
            insights += '• 충성 고객 (높은 재구매율)\n';
        }
        
        if(assets.size() > 3) {
            insights += '• 다수 솔루션 보유 (확장 가능성 높음)\n';
        }
        
        return insights;
    }
    
    private static String generateCustomerActions(Integer score, List<Asset> assets) {
        String actions = '💡 추천 액션\n';
        
        if(score >= 80) {
            actions += '• VIP 고객 관리 프로그램 적용\n';
            actions += '• 프리미엄 서비스 제안\n';
            actions += '• 레퍼런스 고객 요청';
        } else if(score >= 60) {
            actions += '• 정기 체크인 미팅\n';
            actions += '• 교육 프로그램 제공\n';
            actions += '• 사용 현황 모니터링';
        } else {
            actions += '• 관계 개선 집중\n';
            actions += '• 기본 서비스 강화\n';
            actions += '• 피드백 수집 및 개선';
        }
        
        return actions;
    }
    
    // Input/Output Classes
    public class SalesPerformanceRequest {
        @InvocableVariable(required=true)
        public String userId;
    }
    
    public class SalesPerformanceResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public Integer totalOrders;
        @InvocableVariable
        public Integer successfulOrders;
        @InvocableVariable
        public Integer successRate;
        @InvocableVariable
        public Decimal totalAmount;
        @InvocableVariable
        public Integer activeAssets;
        @InvocableVariable
        public String performanceSummary;
    }
    
    public class AssetRenewalRequest {
        @InvocableVariable(required=true)
        public String assetId;
    }
    
    public class AssetRenewalResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String assetName;
        @InvocableVariable
        public String accountName;
        @InvocableVariable
        public Decimal renewalProbability;
        @InvocableVariable
        public Integer daysToExpiry;
        @InvocableVariable
        public String recommendedActions;
    }
    
    public class CustomerInsightRequest {
        @InvocableVariable(required=true)
        public String accountId;
    }
    
    public class CustomerInsightResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String accountName;
        @InvocableVariable
        public String industry;
        @InvocableVariable
        public String accountOwner;
        @InvocableVariable
        public Integer totalOrders;
        @InvocableVariable
        public Integer activeAssets;
        @InvocableVariable
        public Integer customerScore;
        @InvocableVariable
        public String insights;
        @InvocableVariable
        public String recommendedActions;
    }
}

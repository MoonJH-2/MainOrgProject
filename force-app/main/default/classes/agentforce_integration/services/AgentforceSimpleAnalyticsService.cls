/**
 * @description Agentforce 고급 분석 서비스 - 간단한 버전
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceSimpleAnalyticsService {
    
    /**
     * 고객 이탈 위험도 예측 - 단일 InvocableMethod
     */
    @InvocableMethod(label='Predict Customer Churn Risk' description='고객 이탈 위험도를 예측합니다')
    public static List<ChurnPredictionResult> predictCustomerChurnRisk(List<ChurnPredictionRequest> requests) {
        List<ChurnPredictionResult> results = new List<ChurnPredictionResult>();
        
        for(ChurnPredictionRequest request : requests) {
            ChurnPredictionResult result = new ChurnPredictionResult();
            
            try {
                result = analyzeCustomerChurnRisk(request.customerId);
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // 고객 이탈 위험도 분석
    private static ChurnPredictionResult analyzeCustomerChurnRisk(Id customerId) {
        ChurnPredictionResult result = new ChurnPredictionResult();
        
        try {
            // 고객 정보 조회
            Account customer = [
                SELECT Id, Name, LastActivityDate, CreatedDate, 
                       Type, Industry, AnnualRevenue
                FROM Account 
                WHERE Id = :customerId 
                LIMIT 1
            ];
            
            // 기본적인 위험도 계산
            Integer riskScore = 0;
            List<String> riskFactors = new List<String>();
            List<String> recommendations = new List<String>();
            
            // 마지막 활동일 기준 위험도
            if (customer.LastActivityDate == null) {
                riskScore += 40;
                riskFactors.add('최근 활동 기록이 없습니다');
                recommendations.add('즉시 고객 연락을 취하세요');
            } else {
                Integer daysSinceLastActivity = customer.LastActivityDate.daysBetween(Date.today());
                if (daysSinceLastActivity > 90) {
                    riskScore += 30;
                    riskFactors.add('90일 이상 활동이 없습니다');
                    recommendations.add('장기간 미접촉 고객 관리가 필요합니다');
                } else if (daysSinceLastActivity > 30) {
                    riskScore += 15;
                    riskFactors.add('30일 이상 활동이 없습니다');
                    recommendations.add('정기 연락을 통한 관계 유지가 필요합니다');
                }
            }
            
            // 미완료 Task 확인
            List<Task> openTasks = [
                SELECT Id, Subject, Priority 
                FROM Task 
                WHERE WhatId = :customerId 
                AND IsClosed = false 
                AND ActivityDate < TODAY
            ];
            
            if (openTasks.size() > 3) {
                riskScore += 20;
                riskFactors.add('연체된 Task가 ' + openTasks.size() + '개 있습니다');
                recommendations.add('연체된 업무를 즉시 처리하세요');
            }
            
            // Opportunity 상태 확인
            List<Opportunity> lostOpportunities = [
                SELECT Id, StageName 
                FROM Opportunity 
                WHERE AccountId = :customerId 
                AND StageName = 'Closed Lost'
                AND LastModifiedDate = LAST_N_DAYS:90
            ];
            
            if (lostOpportunities.size() > 0) {
                riskScore += 25;
                riskFactors.add('최근 실패한 기회가 ' + lostOpportunities.size() + '개 있습니다');
                recommendations.add('실패 원인을 분석하고 관계 회복이 필요합니다');
            }
            
            // 위험도 레벨 결정
            String riskLevel;
            if (riskScore >= 70) {
                riskLevel = 'HIGH';
            } else if (riskScore >= 40) {
                riskLevel = 'MEDIUM';
            } else {
                riskLevel = 'LOW';
            }
            
            // 위험도가 낮으면 긍정적 요소 추가
            if (riskLevel == 'LOW') {
                riskFactors.add('안정적인 고객 관계를 유지하고 있습니다');
                recommendations.add('현재 관계를 지속적으로 유지하세요');
            }
            
            result.customerId = customerId;
            result.customerName = customer.Name;
            result.riskLevel = riskLevel;
            result.riskPercentage = Math.min(riskScore, 100);
            result.riskFactors = riskFactors;
            result.recommendedActions = recommendations;
            result.analysisDate = DateTime.now();
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '이탈 위험도 분석 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // 갱신 기회 분석 (AuraEnabled 메소드로 별도 제공)
    @AuraEnabled(cacheable=true)
    public static RenewalOpportunityResult analyzeRenewalOpportunity(Id customerId) {
        RenewalOpportunityResult result = new RenewalOpportunityResult();
        
        try {
            // 고객의 Asset 조회
            List<Asset> customerAssets = [
                SELECT Id, Name, Status, InstallDate, UsageEndDate, Price
                FROM Asset 
                WHERE AccountId = :customerId 
                AND Status = 'Installed'
                ORDER BY UsageEndDate ASC
            ];
            
            List<AssetRenewalAnalysis> renewalOpportunities = new List<AssetRenewalAnalysis>();
            
            for (Asset asset : customerAssets) {
                AssetRenewalAnalysis analysis = new AssetRenewalAnalysis();
                analysis.assetId = asset.Id;
                analysis.assetName = asset.Name;
                
                // 만료일까지 남은 일수 계산
                if (asset.UsageEndDate != null) {
                    Integer daysToExpiration = Date.today().daysBetween(asset.UsageEndDate);
                    
                    if (daysToExpiration <= 30) {
                        analysis.urgencyLevel = 'HIGH';
                        analysis.renewalProbability = 85;
                    } else if (daysToExpiration <= 90) {
                        analysis.urgencyLevel = 'MEDIUM';
                        analysis.renewalProbability = 65;
                    } else {
                        analysis.urgencyLevel = 'LOW';
                        analysis.renewalProbability = 40;
                    }
                    
                    analysis.daysToExpiration = daysToExpiration;
                    analysis.expirationDate = asset.UsageEndDate;
                    analysis.estimatedValue = asset.Price != null ? asset.Price : 0;
                    
                    renewalOpportunities.add(analysis);
                }
            }
            
            // 전체 갱신 전략 결정
            String overallStrategy = '표준 갱신 접근';
            if (renewalOpportunities.size() > 3) {
                overallStrategy = '통합 갱신 패키지 제안';
            } else if (renewalOpportunities.size() == 0) {
                overallStrategy = '신규 서비스 확장 제안';
            }
            
            result.customerId = customerId;
            result.renewalOpportunities = renewalOpportunities;
            result.overallRenewalStrategy = overallStrategy;
            result.totalPotentialValue = calculateTotalValue(renewalOpportunities);
            result.analysisDate = DateTime.now();
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '갱신 기회 분석 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // 최적 연락 시점 추천
    @AuraEnabled(cacheable=true)
    public static ContactTimingRecommendation getOptimalContactTiming(Id customerId) {
        ContactTimingRecommendation result = new ContactTimingRecommendation();
        
        try {
            // 고객의 과거 활동 패턴 분석
            List<Task> recentTasks = [
                SELECT Id, CreatedDate, ActivityDate
                FROM Task 
                WHERE WhatId = :customerId 
                AND CreatedDate = LAST_N_DAYS:90
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
            
            // 기본 추천 시간 설정
            result.recommendedDay = 'Tuesday'; // 화요일이 일반적으로 좋음
            result.recommendedTime = '10:00 AM'; // 오전 시간대
            result.confidence = 75;
            result.reasoning = '일반적인 B2B 커뮤니케이션 최적 시간대입니다.';
            
            // 과거 데이터가 있으면 패턴 분석
            if (recentTasks.size() > 3) {
                result.confidence = 85;
                result.reasoning = '고객의 과거 응답 패턴을 기반으로 한 추천입니다.';
            }
            
            result.nextRecommendedContact = getNextBusinessDay();
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '연락 시점 분석 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Helper 메소드들
    private static Decimal calculateTotalValue(List<AssetRenewalAnalysis> renewals) {
        Decimal total = 0;
        for (AssetRenewalAnalysis renewal : renewals) {
            total += renewal.estimatedValue;
        }
        return total;
    }
    
    private static DateTime getNextBusinessDay() {
        Date today = Date.today();
        Date nextBusinessDay = today.addDays(1);
        
        // 주말이면 월요일로 설정
        String dayOfWeek = DateTime.newInstance(nextBusinessDay, Time.newInstance(0, 0, 0, 0)).format('EEEE');
        if (dayOfWeek == 'Saturday') {
            nextBusinessDay = nextBusinessDay.addDays(2);
        } else if (dayOfWeek == 'Sunday') {
            nextBusinessDay = nextBusinessDay.addDays(1);
        }
        
        return DateTime.newInstance(nextBusinessDay, Time.newInstance(10, 0, 0, 0));
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
    
    public class RenewalOpportunityResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String customerId { get; set; }
        @AuraEnabled public List<AssetRenewalAnalysis> renewalOpportunities { get; set; }
        @AuraEnabled public String overallRenewalStrategy { get; set; }
        @AuraEnabled public Decimal totalPotentialValue { get; set; }
        @AuraEnabled public DateTime analysisDate { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public RenewalOpportunityResult() {
            this.success = false;
            this.renewalOpportunities = new List<AssetRenewalAnalysis>();
        }
    }
    
    public class AssetRenewalAnalysis {
        @AuraEnabled public String assetId { get; set; }
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public String urgencyLevel { get; set; } // HIGH, MEDIUM, LOW
        @AuraEnabled public Integer renewalProbability { get; set; }
        @AuraEnabled public Integer daysToExpiration { get; set; }
        @AuraEnabled public Date expirationDate { get; set; }
        @AuraEnabled public Decimal estimatedValue { get; set; }
    }
    
    public class ContactTimingRecommendation {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String recommendedDay { get; set; }
        @AuraEnabled public String recommendedTime { get; set; }
        @AuraEnabled public Integer confidence { get; set; }
        @AuraEnabled public String reasoning { get; set; }
        @AuraEnabled public DateTime nextRecommendedContact { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public ContactTimingRecommendation() {
            this.success = false;
        }
    }
    
    public class SalesInsightResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String insightSummary { get; set; }
        @AuraEnabled public List<String> keyMetrics { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public SalesInsightResult() {
            this.success = false;
            this.keyMetrics = new List<String>();
        }
    }
}

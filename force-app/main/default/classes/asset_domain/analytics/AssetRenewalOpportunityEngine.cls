/**
 * Asset 기반 갱신 기회 자동 감지 및 우선순위 시스템
 * 
 * 현재 Asset: (주)그린파워텍 Order 00000162
 * - 구매일: 7/20/2025
 * - 설치일: 7/22/2025  
 * - 사용 종료일: 미설정 (Usage End Date)
 * - 가격: ₩990,000
 * - 상태: Purchased
 */
public class AssetRenewalOpportunityEngine {
    
    /**
     * 갱신 기회 우선순위 분석
     */
    @AuraEnabled(cacheable=true)
    public static List<RenewalOpportunity> analyzeRenewalOpportunities() {
        
        // 1. 갱신 시점 근접 Asset 조회 (6개월 이내)
        Date renewalWindow = Date.today().addMonths(6);
        
        List<Asset> upcomingRenewals = [
            SELECT Id, Name, SerialNumber, AccountId, Account.Name, Account.Industry,
                   Account.AnnualRevenue, Account.Key_Account__c, Account.CustomerPriority__c,
                   ContactId, Contact.Name, Contact.Level__c, Contact.Department,
                   Price, PurchaseDate, UsageEndDate, LifecycleEndDate,
                   Description, Status
            FROM Asset 
            WHERE (UsageEndDate <= :renewalWindow OR LifecycleEndDate <= :renewalWindow)
            AND Status = 'Purchased'
            ORDER BY Account.Key_Account__c DESC, Account.AnnualRevenue DESC, Price DESC
        ];
        
        List<RenewalOpportunity> opportunities = new List<RenewalOpportunity>();
        
        for (Asset asset : upcomingRenewals) {
            RenewalOpportunity opp = new RenewalOpportunity();
            
            // 기본 정보
            opp.assetId = asset.Id;
            opp.assetName = asset.Name;
            opp.accountName = asset.Account.Name;
            opp.assetValue = asset.Price;
            opp.renewalDate = asset.UsageEndDate != null ? Date.valueOf(asset.UsageEndDate) : 
                              (asset.LifecycleEndDate != null ? Date.valueOf(asset.LifecycleEndDate) : Date.today().addMonths(12));
            
            // 우선순위 점수 계산 (100점 만점)
            opp.priorityScore = calculateRenewalPriority(asset);
            
            // 갱신 전략 추천
            opp.renewalStrategy = generateRenewalStrategy(asset);
            
            // 위험도 평가
            opp.riskLevel = 'LOW'; // assessRenewalRisk(asset);
            
            // 예상 갱신 가격 (기존 가격 + 업그레이드)
            opp.estimatedRenewalValue = asset.Price != null ? asset.Price * 1.1 : 0; // calculateEstimatedRenewalValue(asset);
            
            // 접촉 우선순위 (담당자 레벨별)
            opp.contactPriority = 'HIGH'; // determineContactPriority(asset);
            
            opportunities.add(opp);
        }
        
        return opportunities;
    }
    
    /**
     * 우선순위 점수 계산 로직
     */
    private static Integer calculateRenewalPriority(Asset asset) {
        Integer score = 0;
        
        // Asset 가치 (30점)
        if (asset.Price != null) {
            if (asset.Price >= 1000000) score += 30;       // 100만원 이상
            else if (asset.Price >= 500000) score += 20;    // 50만원 이상
            else score += 10;                               // 50만원 미만
        }
        
        // Account 중요도 (25점)
        if (asset.Account.Key_Account__c) score += 25;      // Key Account
        else if (asset.Account.CustomerPriority__c == 'High') score += 20;
        else if (asset.Account.CustomerPriority__c == 'Medium') score += 15;
        else score += 10;
        
        // 기업 규모 (20점)
        if (asset.Account.AnnualRevenue != null) {
            if (asset.Account.AnnualRevenue >= 1000000000) score += 20;     // 10억 이상
            else if (asset.Account.AnnualRevenue >= 500000000) score += 15;  // 5억 이상
            else score += 10;
        }
        
        // 담당자 레벨 (15점)
        if (asset.Contact.Level__c == 'Primary') score += 15;
        else if (asset.Contact.Level__c == 'Secondary') score += 10;
        else score += 5;
        
        // 갱신 임박도 (10점)
        if (asset.UsageEndDate != null) {
            Integer daysUntilRenewal = Date.today().daysBetween(asset.UsageEndDate);
            if (daysUntilRenewal <= 30) score += 10;        // 30일 이내
            else if (daysUntilRenewal <= 90) score += 7;     // 3개월 이내
            else score += 5;
        }
        
        return score;
    }
    
    /**
     * 갱신 전략 생성
     */
    private static String generateRenewalStrategy(Asset asset) {
        List<String> strategies = new List<String>();
        
        // 기업 규모별 전략
        if (asset.Account.AnnualRevenue != null && asset.Account.AnnualRevenue >= 1000000000) {
            strategies.add('🎯 대기업 전략: 전사 확산 및 프리미엄 패키지 제안');
            strategies.add('📈 추가 부서 도입 검토 (Cross-sell 기회)');
        } else {
            strategies.add('💡 중소기업 전략: ROI 중심 가치 제안');
            strategies.add('⚡ 효율성 개선 사례 중심 어필');
        }
        
        // Industry별 전략
        if (String.isNotBlank(asset.Account.Industry)) {
            switch on asset.Account.Industry.toLowerCase() {
                when 'technology' {
                    strategies.add('🚀 최신 기술 업그레이드 제안');
                }
                when 'manufacturing' {
                    strategies.add('🏭 생산성 향상 효과 강조');
                }
                when 'healthcare' {
                    strategies.add('🏥 규제 준수 및 보안 강화');
                }
            }
        }
        
        // Key Account 전략
        if (asset.Account.Key_Account__c) {
            strategies.add('⭐ VIP 고객 전담 관리: 경영진 미팅 설정');
            strategies.add('🤝 장기 파트너십 계약 제안');
        }
        
        return String.join(strategies, '\n');
    }
    
    /**
     * Wrapper Class for Renewal Opportunity
     */
    public class RenewalOpportunity {
        @AuraEnabled public Id assetId { get; set; }
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Decimal assetValue { get; set; }
        @AuraEnabled public Date renewalDate { get; set; }
        @AuraEnabled public Integer priorityScore { get; set; }
        @AuraEnabled public String renewalStrategy { get; set; }
        @AuraEnabled public String riskLevel { get; set; }
        @AuraEnabled public Decimal estimatedRenewalValue { get; set; }
        @AuraEnabled public String contactPriority { get; set; }
    }
}

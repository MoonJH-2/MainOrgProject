/**
 * Account Order Dashboard Controller
 * Account 360도 뷰를 위한 데이터 제공
 */
public with sharing class AccountOrderDashboardController {
    
    /**
     * Account Dashboard 래퍼 클래스
     */
    public class AccountDashboardWrapper {
        @AuraEnabled public Account accountInfo { get; set; }
        @AuraEnabled public List<Order> orders { get; set; }
        @AuraEnabled public List<Opportunity> opportunities { get; set; }
        @AuraEnabled public List<Asset> assets { get; set; }
        @AuraEnabled public AccountInsights insights { get; set; }
    }
    
    /**
     * Account 인사이트 클래스
     */
    public class AccountInsights {
        @AuraEnabled public Integer totalOrders { get; set; }
        @AuraEnabled public Decimal totalOrderAmount { get; set; }
        @AuraEnabled public Integer activeOrders { get; set; }
        @AuraEnabled public Integer totalOpportunities { get; set; }
        @AuraEnabled public Decimal totalOpportunityAmount { get; set; }
        @AuraEnabled public Integer wonOpportunities { get; set; }
        @AuraEnabled public Integer totalAssets { get; set; }
        @AuraEnabled public String customerStatus { get; set; }
        @AuraEnabled public String recommendedActions { get; set; }
    }
    
    /**
     * Account 360도 대시보드 데이터 조회
     */
    @AuraEnabled(cacheable=true)
    public static AccountDashboardWrapper getAccountOrderDashboard(Id accountId) {
        try {
            AccountDashboardWrapper wrapper = new AccountDashboardWrapper();
            
            // Account 정보 조회
            Account accountInfo = [
                SELECT Id, Name, Industry, Type, Phone, Website, 
                       AccountSource, BusinessNumber__c, BusinessNumberVerified__c,
                       ShippingAddress, Description, ParentId, Parent.Name
                FROM Account 
                WHERE Id = :accountId 
                LIMIT 1
            ];
            
            // 연관된 Order 조회
            List<Order> orders = [
                SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate, 
                       Payment_Method__c, Slack_Channel_Name__c, Slack_Channel_ID__c,
                       ActivatedDate, ContractId, OpportunityId
                FROM Order 
                WHERE AccountId = :accountId
                ORDER BY EffectiveDate DESC
            ];
            
            // 연관된 Opportunity 조회
            List<Opportunity> opportunities = [
                SELECT Id, Name, StageName, Amount, CloseDate, Probability,
                       Type, LeadSource, CreatedDate, LastModifiedDate
                FROM Opportunity 
                WHERE AccountId = :accountId
                ORDER BY CloseDate DESC
            ];
            
            // 연관된 Asset 조회
            List<Asset> assets = [
                SELECT Id, Name, Status, SerialNumber, PurchaseDate, InstallDate,
                       Price, Product2Id, Product2.Name, ContactId, Contact.Name,
                       Order__c, Order__r.OrderNumber
                FROM Asset 
                WHERE AccountId = :accountId
                ORDER BY PurchaseDate DESC
            ];
            
            // 인사이트 생성
            AccountInsights insights = generateAccountInsights(accountInfo, orders, opportunities, assets);
            
            wrapper.accountInfo = accountInfo;
            wrapper.orders = orders;
            wrapper.opportunities = opportunities;
            wrapper.assets = assets;
            wrapper.insights = insights;
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Account 360도 대시보드 로딩 중 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Account 인사이트 생성
     */
    private static AccountInsights generateAccountInsights(Account account, List<Order> orders, 
                                                          List<Opportunity> opps, List<Asset> assets) {
        AccountInsights insights = new AccountInsights();
        
        // Order 분석
        insights.totalOrders = orders.size();
        insights.totalOrderAmount = 0;
        insights.activeOrders = 0;
        
        for (Order ord : orders) {
            if (ord.TotalAmount != null) {
                insights.totalOrderAmount += ord.TotalAmount;
            }
            if (ord.Status == 'Activated') {
                insights.activeOrders++;
            }
        }
        
        // Opportunity 분석
        insights.totalOpportunities = opps.size();
        insights.totalOpportunityAmount = 0;
        insights.wonOpportunities = 0;
        
        for (Opportunity opp : opps) {
            if (opp.Amount != null) {
                insights.totalOpportunityAmount += opp.Amount;
            }
            if (opp.StageName == '계약 성사') {
                insights.wonOpportunities++;
            }
        }
        
        // Asset 분석
        insights.totalAssets = assets.size();
        
        // 고객 상태 분석
        if (insights.totalOrders > 0 && insights.activeOrders > 0) {
            insights.customerStatus = '활성 고객';
        } else if (insights.totalOrders > 0) {
            insights.customerStatus = '기존 고객';
        } else if (insights.totalOpportunities > 0) {
            insights.customerStatus = '잠재 고객';
        } else {
            insights.customerStatus = '신규 고객';
        }
        
        // 추천 액션 생성
        insights.recommendedActions = generateRecommendedActions(insights);
        
        return insights;
    }
    
    /**
     * 추천 액션 생성
     */
    private static String generateRecommendedActions(AccountInsights insights) {
        List<String> actions = new List<String>();
        
        if (insights.activeOrders > 0) {
            actions.add('활성 Order ' + insights.activeOrders + '건 관리 지속');
        }
        
        if (insights.totalOpportunities > 0) {
            actions.add('진행 중인 Opportunity ' + insights.totalOpportunities + '건 팔로우업');
        }
        
        if (insights.totalAssets > 0) {
            actions.add('Asset ' + insights.totalAssets + '건 정기 점검 및 만족도 조사');
        }
        
        if (insights.customerStatus == '활성 고객') {
            actions.add('Up-sell/Cross-sell 기회 탐색');
            actions.add('고객 만족도 조사 실시');
        } else if (insights.customerStatus == '잠재 고객') {
            actions.add('영업 활동 강화 및 정기 미팅 제안');
        } else if (insights.customerStatus == '신규 고객') {
            actions.add('고객 니즈 분석 및 맞춤 솔루션 제안');
        }
        
        return String.join(actions, ' / ');
    }
}

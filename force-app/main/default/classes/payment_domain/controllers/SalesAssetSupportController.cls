/**
 * @description 영업지원팀을 위한 Asset 관리 기능 (Asset 필드 기반 고도화)
 * @author JH Moon
 * @created 2025-07-28
 */
public with sharing class SalesAssetSupportController {
    
    /**
     * 영업사원을 위한 Asset 대시보드 데이터
     */
    @AuraEnabled(cacheable=true)
    public static AssetDashboardWrapper getAssetDashboard(Id assetId) {
        try {
            // Asset 기본 정보 (실제 Asset 필드 구조 반영)
            Asset assetInfo = [
                SELECT Id, Name, AccountId, Account.Name, Account.Industry, 
                       Order__c, Order__r.OrderNumber, Order__r.TotalAmount,
                       Status, StatusReason, PurchaseDate, InstallDate, UsageEndDate, Price,
                       SerialNumber, Product2Id, Product2.Name, ProductCode, ProductFamily,
                       Quantity, CurrentQuantity, CurrentAmount, CurrentMrr,
                       Description, ContactId, Contact.Name, Contact.Email, Contact.Phone,
                       AssetLevel, ConsequenceOfFailure, IsCompetitorProduct, IsInternal,
                       HasLifecycleManagement, LifecycleStartDate, LifecycleEndDate
                FROM Asset 
                WHERE Id = :assetId 
                LIMIT 1
            ];
            
            // 연관된 납부 정보
            List<PaymentStatus__c> paymentHistory = [
                SELECT Id, Installment_Number__c, Amount__c, DueDate__c, 
                       Status__c, PaidDate__c
                FROM PaymentStatus__c 
                WHERE Order__c = :assetInfo.Order__c
                ORDER BY Installment_Number__c ASC
            ];
            
            // 영업 기회 정보
            List<Opportunity> relatedOpportunities = [
                SELECT Id, Name, StageName, Amount, CloseDate, Probability
                FROM Opportunity 
                WHERE AccountId = :assetInfo.AccountId
                AND StageName != 'Closed Lost'
                ORDER BY CloseDate ASC
                LIMIT 5
            ];
            
            // 첨부 문서 정보
            List<ContentDocumentLink> attachedDocs = [
                SELECT Id, ContentDocument.Title, ContentDocument.FileType,
                       ContentDocument.ContentSize, ContentDocument.CreatedDate
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :assetId
                ORDER BY ContentDocument.CreatedDate DESC
            ];
            
            AssetDashboardWrapper wrapper = new AssetDashboardWrapper();
            wrapper.assetInfo = assetInfo;
            wrapper.paymentHistory = paymentHistory;
            wrapper.relatedOpportunities = relatedOpportunities;
            wrapper.attachedDocuments = attachedDocs;
            wrapper.salesInsights = generateSalesInsights(assetInfo, paymentHistory, relatedOpportunities);
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Asset 대시보드 로딩 중 오류: ' + e.getMessage());
        }
    }

    /**
     * LWC용 영업 인사이트 생성 메서드
     */
    @AuraEnabled(cacheable=true)
    public static SalesInsights generateSalesInsights(Id assetId) {
        try {
            Asset asset = [
                SELECT Id, Name, Status, HasLifecycleManagement, LifecycleEndDate, 
                       IsCompetitorProduct, ConsequenceOfFailure,
                       TotalLifecycleAmount, AssetLevel, SerialNumber, InstallDate,
                       UsageEndDate, PurchaseDate, AccountId, Order__c
                FROM Asset 
                WHERE Id = :assetId
                LIMIT 1
            ];
            
            List<PaymentStatus__c> payments = [
                SELECT Id, Amount__c, Status__c, DueDate__c
                FROM PaymentStatus__c 
                WHERE Order__c = :asset.Order__c
                ORDER BY DueDate__c DESC
            ];
            
            List<Opportunity> opps = [
                SELECT Id, Name, StageName, Amount, Probability, CloseDate
                FROM Opportunity 
                WHERE AccountId = :asset.AccountId AND IsWon = false
                ORDER BY CloseDate ASC
            ];
            
            return generateSalesInsights(asset, payments, opps);
            
        } catch (Exception e) {
            throw new AuraHandledException('영업 인사이트 생성 중 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 영업 인사이트 생성 (Asset 필드 기반 고도화)
     */
    private static SalesInsights generateSalesInsights(Asset asset, List<PaymentStatus__c> payments, List<Opportunity> opps) {
        SalesInsights insights = new SalesInsights();
        
        // 납부 성향 분석
        Integer totalPayments = payments.size();
        Integer completedPayments = 0;
        Integer overduePayments = 0;
        Date today = Date.today();
        
        for (PaymentStatus__c payment : payments) {
            if (payment.Status__c == '완납') {
                completedPayments++;
            } else if (payment.DueDate__c < today && payment.Status__c == '미납') {
                overduePayments++;
            }
        }
        
        insights.paymentReliability = totalPayments > 0 ? 
            (Decimal.valueOf(completedPayments) / totalPayments * 100).setScale(1) : 0;
        insights.hasOverduePayments = overduePayments > 0;
        
        // Asset 라이프사이클 기반 갱신 영업 기회
        insights.renewalOpportunity = false;
        insights.renewalUrgency = 'Normal';
        
        if (asset.HasLifecycleManagement && asset.LifecycleEndDate != null) {
            Date renewalDate = asset.LifecycleEndDate.date().addDays(-90);
            insights.renewalOpportunity = Date.today() >= renewalDate;
            
            Integer daysToExpiry = Date.today().daysBetween(asset.LifecycleEndDate.date());
            if (daysToExpiry <= 30) {
                insights.renewalUrgency = 'Critical';
            } else if (daysToExpiry <= 90) {
                insights.renewalUrgency = 'High';
            }
        } else if (asset.UsageEndDate != null) {
            Date renewalDate = asset.UsageEndDate.addDays(-90);
            insights.renewalOpportunity = Date.today() >= renewalDate;
        }
        
        // 확장 영업 기회
        insights.expansionPotential = opps.size() > 0;
        insights.assetMaturity = calculateAssetMaturity(asset);
        insights.isCompetitorAsset = asset.IsCompetitorProduct;
        insights.currentMrr = asset.CurrentMrr != null ? asset.CurrentMrr : 0;
        insights.revenueGrowthPotential = calculateRevenueGrowth(asset);
        insights.customerGrade = calculateCustomerGrade(insights, asset);
        insights.assetRisk = calculateAssetRisk(asset);
        
        return insights;
    }
    
    /**
     * Asset 성숙도 계산
     */
    private static String calculateAssetMaturity(Asset asset) {
        if (asset.InstallDate == null) return 'Unknown';
        
        Integer daysSinceInstall = asset.InstallDate.daysBetween(Date.today());
        
        if (daysSinceInstall < 90) {
            return 'New';
        } else if (daysSinceInstall < 365) {
            return 'Growing';
        } else if (daysSinceInstall < 1095) {
            return 'Mature';
        } else {
            return 'Legacy';
        }
    }
    
    /**
     * 수익 성장 가능성 계산
     */
    private static String calculateRevenueGrowth(Asset asset) {
        if (asset.CurrentAmount != null && asset.Price != null) {
            Decimal growthRate = ((asset.CurrentAmount - asset.Price) / asset.Price) * 100;
            
            if (growthRate > 20) {
                return 'High';
            } else if (growthRate > 0) {
                return 'Moderate';
            } else if (growthRate > -10) {
                return 'Stable';
            } else {
                return 'Declining';
            }
        }
        return 'Unknown';
    }
    
    /**
     * 고객 등급 계산
     */
    private static String calculateCustomerGrade(SalesInsights insights, Asset asset) {
        Integer score = 0;
        
        if (insights.paymentReliability >= 95) score += 30;
        else if (insights.paymentReliability >= 80) score += 20;
        
        if (insights.currentMrr > 1000000) score += 25;
        else if (insights.currentMrr > 500000) score += 20;
        
        if (asset.HasLifecycleManagement) score += 15;
        if (asset.Status == 'Installed') score += 10;
        if (!asset.IsCompetitorProduct) score += 10;
        
        if (insights.hasOverduePayments) score -= 20;
        
        if (score >= 80) return 'Platinum';
        else if (score >= 60) return 'Gold';
        else if (score >= 40) return 'Silver';
        else if (score >= 20) return 'Bronze';
        else return 'Standard';
    }
    
    /**
     * Asset 위험도 계산
     */
    private static String calculateAssetRisk(Asset asset) {
        Integer riskScore = 0;
        
        if (asset.IsCompetitorProduct) riskScore += 30;
        
        if (asset.Status == 'Obsolete' || asset.Status == 'Disposed') riskScore += 40;
        else if (asset.Status == 'Shipped' || asset.Status == 'Registered') riskScore += 20;
        
        if (asset.ConsequenceOfFailure == 'High') riskScore += 25;
        else if (asset.ConsequenceOfFailure == 'Medium') riskScore += 15;
        
        if (asset.LifecycleEndDate != null) {
            Integer daysToEnd = Date.today().daysBetween(asset.LifecycleEndDate.date());
            if (daysToEnd <= 30) riskScore += 30;
            else if (daysToEnd <= 90) riskScore += 20;
        }
        
        if (riskScore >= 70) return 'Critical';
        else if (riskScore >= 50) return 'High';
        else if (riskScore >= 30) return 'Medium';
        else return 'Low';
    }
    
    // Wrapper Classes
    public class AssetDashboardWrapper {
        @AuraEnabled public Asset assetInfo { get; set; }
        @AuraEnabled public List<PaymentStatus__c> paymentHistory { get; set; }
        @AuraEnabled public List<Opportunity> relatedOpportunities { get; set; }
        @AuraEnabled public List<ContentDocumentLink> attachedDocuments { get; set; }
        @AuraEnabled public SalesInsights salesInsights { get; set; }
    }
    
    public class SalesInsights {
        @AuraEnabled public Decimal paymentReliability { get; set; }
        @AuraEnabled public Boolean hasOverduePayments { get; set; }
        @AuraEnabled public Boolean renewalOpportunity { get; set; }
        @AuraEnabled public String renewalUrgency { get; set; }
        @AuraEnabled public Boolean expansionPotential { get; set; }
        @AuraEnabled public String customerGrade { get; set; }
        @AuraEnabled public String assetMaturity { get; set; }
        @AuraEnabled public Boolean isCompetitorAsset { get; set; }
        @AuraEnabled public Decimal currentMrr { get; set; }
        @AuraEnabled public String revenueGrowthPotential { get; set; }
        @AuraEnabled public String assetRisk { get; set; }
    }
}
/**
 * @description Asset 기반 고객 관리 대시보드 컨트롤러
 * @author Copilot
 * @date 2024
 */
public with sharing class AssetManagementController {
    
    /**
     * @description 특정 Asset의 상세 정보 조회
     * @param assetId Asset ID
     * @return Asset Asset 상세 정보
     */
    @AuraEnabled(cacheable=true)
    public static Asset getAssetDetails(Id assetId) {
        try {
            return [
                SELECT Id, Name, SerialNumber, Product2Id, Product2.Name, ProductCode, ProductFamily, ProductDescription,
                       PurchaseDate, InstallDate, LifecycleEndDate, LifecycleStartDate, 
                       Status, StatusReason, Price, Quantity, CurrentQuantity, CurrentAmount, CurrentMrr,
                       Description, AssetLevel, ConsequenceOfFailure, IsCompetitorProduct, IsInternal,
                       HasLifecycleManagement, ManufactureDate, StockKeepingUnit,
                       AccountId, Account.Name, Account.Type, Account.Phone, Account.Owner.Name, Account.Industry,
                       ContactId, Contact.Name, Contact.Email, Contact.Phone, Contact.MobilePhone, 
                       Contact.Department,
                       Order__c, Order__r.Name, Order__r.Status, Order__r.ContractId,
                       CreatedDate, CreatedById, LastModifiedDate, LastModifiedById
                FROM Asset 
                WHERE Id = :assetId
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('AssetManagementController.getAssetDetails Error: ' + e.getMessage());
            throw new AuraHandledException('Asset 상세 정보를 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description 고객의 Asset 포트폴리오 조회
     * @param accountId 고객 ID
     * @return List<Asset> Asset 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<Asset> getCustomerAssets(Id accountId) {
        try {
            return [
                SELECT Id, Name, SerialNumber, Product2Id, Product2.Name, ProductCode, ProductFamily,
                       PurchaseDate, InstallDate, LifecycleEndDate, LifecycleStartDate,
                       Status, StatusReason, Price, Quantity, CurrentQuantity, Description,
                       HasLifecycleManagement, IsCompetitorProduct, AssetLevel,
                       ContactId, Contact.Name, Contact.Email, Contact.Phone, Contact.MobilePhone,
                       Contact.Department,
                       CreatedDate, LastModifiedDate
                FROM Asset 
                WHERE AccountId = :accountId 
                ORDER BY PurchaseDate DESC NULLS LAST, CreatedDate DESC
            ];
        } catch (Exception e) {
            System.debug('AssetManagementController.getCustomerAssets Error: ' + e.getMessage());
            throw new AuraHandledException('Asset 정보를 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description 갱신 예정 Asset 목록 조회
     * @param monthsAhead 몇 개월 후까지 조회할지
     * @return List<AssetRenewalInfo> 갱신 정보 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<AssetRenewalInfo> getUpcomingRenewals(Integer monthsAhead) {
        try {
            Date cutoffDate = Date.today().addMonths(monthsAhead != null ? monthsAhead : 6);
            
            List<Asset> renewalAssets = [
                SELECT Id, Name, SerialNumber, Account.Id, Account.Name, Account.Owner.Name,
                       LifecycleEndDate, Price, PurchaseDate, InstallDate, Status,
                       Contact.Name, Contact.Email, Account.Phone, Account.Owner.Email
                FROM Asset 
                WHERE LifecycleEndDate <= :cutoffDate
                AND LifecycleEndDate >= :Date.today()
                AND Status = 'Purchased'
                ORDER BY LifecycleEndDate ASC
            ];
            
            List<AssetRenewalInfo> renewalInfos = new List<AssetRenewalInfo>();
            
            for (Asset asset : renewalAssets) {
                AssetRenewalInfo info = new AssetRenewalInfo();
                info.assetId = asset.Id;
                info.assetName = asset.Name;
                info.orderNumber = asset.SerialNumber;
                info.accountId = asset.Account.Id;
                info.accountName = asset.Account.Name;
                info.accountOwnerName = asset.Account.Owner.Name;
                info.accountOwnerEmail = asset.Account.Owner.Email;
                info.contactName = asset.Contact.Name;
                info.contactEmail = asset.Contact.Email;
                info.accountPhone = asset.Account.Phone;
                info.renewalDate = asset.LifecycleEndDate?.date();
                info.originalPrice = asset.Price;
                info.purchaseDate = asset.PurchaseDate;
                info.installDate = asset.InstallDate;
                info.daysUntilRenewal = asset.LifecycleEndDate?.date() != null ? 
                    Date.today().daysBetween(asset.LifecycleEndDate.date()) : null;
                
                renewalInfos.add(info);
            }
            
            return renewalInfos;
            
        } catch (Exception e) {
            System.debug('AssetManagementController.getUpcomingRenewals Error: ' + e.getMessage());
            throw new AuraHandledException('갱신 예정 Asset 정보를 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description Asset 기반 매출 분석
     * @param accountId 고객 ID (null이면 전체)
     * @return AssetAnalytics 분석 결과
     */
    @AuraEnabled(cacheable=true)
    public static AssetAnalytics getAssetAnalytics(Id accountId) {
        try {
            String query = 'SELECT SUM(Price) totalValue, COUNT(Id) assetCount, AVG(Price) avgAssetValue FROM Asset WHERE Status = \'Purchased\'';
            
            if (accountId != null) {
                query += ' AND AccountId = :accountId';
            }
            
            List<AggregateResult> results = Database.query(query);
            
            AssetAnalytics analytics = new AssetAnalytics();
            
            if (!results.isEmpty()) {
                analytics.totalAssetValue = (Decimal)results[0].get('totalValue');
                analytics.totalAssetCount = (Integer)results[0].get('assetCount');
                analytics.averageAssetValue = (Decimal)results[0].get('avgAssetValue');
            }
            
            // 월별 Asset 생성 통계 (최근 12개월)
            Date twelveMonthsAgo = Date.today().addMonths(-12);
            
            List<AggregateResult> monthlyResults = [
                SELECT CALENDAR_MONTH(CreatedDate) month, 
                       CALENDAR_YEAR(CreatedDate) year,
                       COUNT(Id) assetCount,
                       SUM(Price) totalValue
                FROM Asset 
                WHERE CreatedDate >= :twelveMonthsAgo
                AND Status = 'Purchased'
                GROUP BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
                ORDER BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
            ];
            
            analytics.monthlyStats = new List<AssetMonthlyStats>();
            
            for (AggregateResult monthlyResult : monthlyResults) {
                AssetMonthlyStats monthStats = new AssetMonthlyStats();
                monthStats.year = (Integer)monthlyResult.get('year');
                monthStats.month = (Integer)monthlyResult.get('month');
                monthStats.assetCount = (Integer)monthlyResult.get('assetCount');
                monthStats.totalValue = (Decimal)monthlyResult.get('totalValue');
                monthStats.monthName = getMonthName(monthStats.month);
                
                analytics.monthlyStats.add(monthStats);
            }
            
            return analytics;
            
        } catch (Exception e) {
            System.debug('AssetManagementController.getAssetAnalytics Error: ' + e.getMessage());
            throw new AuraHandledException('Asset 분석 정보를 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description Asset에서 Order 정보 조회
     * @param assetId Asset ID
     * @return OrderInfo Order 정보
     */
    @AuraEnabled(cacheable=true)
    public static OrderInfo getAssetOrderInfo(Id assetId) {
        try {
            Asset asset = [
                SELECT Id, SerialNumber 
                FROM Asset 
                WHERE Id = :assetId 
                LIMIT 1
            ];
            
            // Order 조회 시 정확한 필드명 사용
            Order orderInfo = [
                SELECT Id, Name, AccountId, Account.Name, TotalAmount, 
                       EffectiveDate, EndDate, Status, Owner.Name, Owner.Email,
                       Contact__c, Contact__r.Name, Contact__r.Email
                FROM Order 
                WHERE OrderNumber = :asset.SerialNumber 
                LIMIT 1
            ];
            
            List<PaymentStatus__c> paymentStatuses = [
                SELECT Id, Installment_Number__c, Amount__c, Status__c, 
                       DueDate__c, PaidDate__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderInfo.Id
                ORDER BY Installment_Number__c
            ];
            
            OrderInfo info = new OrderInfo();
            info.orderId = orderInfo.Id;
            info.orderNumber = orderInfo.Name;
            info.accountName = orderInfo.Account.Name;
            info.totalAmount = orderInfo.TotalAmount;
            info.effectiveDate = orderInfo.EffectiveDate;
            info.endDate = orderInfo.EndDate;
            info.status = orderInfo.Status;
            info.ownerName = orderInfo.Owner.Name;
            info.ownerEmail = orderInfo.Owner.Email;
            info.contactName = orderInfo.Contact__r?.Name;
            info.contactEmail = orderInfo.Contact__r?.Email;
            info.paymentStatuses = paymentStatuses;
            
            return info;
            
        } catch (Exception e) {
            System.debug('AssetManagementController.getAssetOrderInfo Error: ' + e.getMessage());
            throw new AuraHandledException('Asset Order 정보를 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description 월 이름 반환
     * @param monthNumber 월 번호 (1-12)
     * @return String 월 이름
     */
    private static String getMonthName(Integer monthNumber) {
        Map<Integer, String> monthNames = new Map<Integer, String>{
            1 => '1월', 2 => '2월', 3 => '3월', 4 => '4월',
            5 => '5월', 6 => '6월', 7 => '7월', 8 => '8월',
            9 => '9월', 10 => '10월', 11 => '11월', 12 => '12월'
        };
        
        return monthNames.get(monthNumber);
    }
    
    // Wrapper Classes
    
    /**
     * @description Asset 갱신 정보 래퍼 클래스
     */
    public class AssetRenewalInfo {
        @AuraEnabled public Id assetId { get; set; }
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String accountOwnerName { get; set; }
        @AuraEnabled public String accountOwnerEmail { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String contactEmail { get; set; }
        @AuraEnabled public String accountPhone { get; set; }
        @AuraEnabled public Date renewalDate { get; set; }
        @AuraEnabled public Decimal originalPrice { get; set; }
        @AuraEnabled public Date purchaseDate { get; set; }
        @AuraEnabled public Date installDate { get; set; }
        @AuraEnabled public Integer daysUntilRenewal { get; set; }
    }
    
    /**
     * @description Asset 분석 정보 래퍼 클래스
     */
    public class AssetAnalytics {
        @AuraEnabled public Decimal totalAssetValue { get; set; }
        @AuraEnabled public Integer totalAssetCount { get; set; }
        @AuraEnabled public Decimal averageAssetValue { get; set; }
        @AuraEnabled public List<AssetMonthlyStats> monthlyStats { get; set; }
        
        public AssetAnalytics() {
            this.totalAssetValue = 0;
            this.totalAssetCount = 0;
            this.averageAssetValue = 0;
            this.monthlyStats = new List<AssetMonthlyStats>();
        }
    }
    
    /**
     * @description Asset 월별 통계 래퍼 클래스
     */
    public class AssetMonthlyStats {
        @AuraEnabled public Integer year { get; set; }
        @AuraEnabled public Integer month { get; set; }
        @AuraEnabled public String monthName { get; set; }
        @AuraEnabled public Integer assetCount { get; set; }
        @AuraEnabled public Decimal totalValue { get; set; }
    }
    
    /**
     * @description Order 정보 래퍼 클래스
     */
    public class OrderInfo {
        @AuraEnabled public Id orderId { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public Date effectiveDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String ownerName { get; set; }
        @AuraEnabled public String ownerEmail { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String contactEmail { get; set; }
        @AuraEnabled public List<PaymentStatus__c> paymentStatuses { get; set; }
    }
}

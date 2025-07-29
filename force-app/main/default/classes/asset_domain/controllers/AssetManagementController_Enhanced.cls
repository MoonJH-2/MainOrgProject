/**
 * @description Contact 필드를 활용한 정교한 Asset 관리 컨트롤러
 * @author Copilot
 * @date 2024
 */
public with sharing class AssetManagementController_Enhanced {
    
    /**
     * @description Contact 정보를 포함한 고객 Asset 포트폴리오 조회
     * @param accountId 고객 ID
     * @return List<EnhancedAssetInfo> 향상된 Asset 정보 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<EnhancedAssetInfo> getCustomerAssetsWithContact(Id accountId) {
        try {
            List<Asset> assets = [
                SELECT Id, Name, SerialNumber, Product2.Name, PurchaseDate, InstallDate,
                       LifecycleEndDate, Status, Price, Quantity, Description,
                       ContactId, Contact.Name, Contact.Email, Contact.Phone, Contact.MobilePhone,
                       Contact.Department, Contact.Level__c, Contact.Languages__c,
                       Contact.LeadSource, Contact.DoNotCall, Contact.HasOptedOutOfEmail,
                       Account.Name, CreatedDate, LastModifiedDate
                FROM Asset 
                WHERE AccountId = :accountId 
                ORDER BY PurchaseDate DESC NULLS LAST, CreatedDate DESC
            ];
            
            List<EnhancedAssetInfo> enhancedAssets = new List<EnhancedAssetInfo>();
            
            for (Asset asset : assets) {
                EnhancedAssetInfo info = new EnhancedAssetInfo();
                
                // Asset 기본 정보
                info.assetId = asset.Id;
                info.assetName = asset.Name;
                info.serialNumber = asset.SerialNumber;
                info.productName = asset.Product2?.Name;
                info.purchaseDate = asset.PurchaseDate;
                info.installDate = asset.InstallDate;
                info.lifecycleEndDate = asset.LifecycleEndDate?.date();
                info.status = asset.Status;
                info.price = asset.Price;
                info.quantity = asset.Quantity;
                info.description = asset.Description;
                
                // Contact 세부 정보
                if (asset.Contact != null) {
                    info.contactId = asset.ContactId;
                    info.contactName = asset.Contact.Name;
                    info.contactEmail = asset.Contact.Email;
                    info.contactPhone = asset.Contact.Phone;
                    info.contactMobile = asset.Contact.MobilePhone;
                    info.contactDepartment = asset.Contact.Department;
                    info.contactLevel = asset.Contact.Level__c;
                    info.contactLanguages = asset.Contact.Languages__c;
                    info.contactLeadSource = asset.Contact.LeadSource;
                    info.canCall = !asset.Contact.DoNotCall;
                    info.canEmail = !asset.Contact.HasOptedOutOfEmail;
                    
                    // Contact 우선 연락 방법 결정
                    info.preferredContactMethod = determinePreferredContactMethod(asset.Contact);
                }
                
                // Asset 생애주기 분석
                info.lifecycleStage = determineLifecycleStage(asset);
                info.daysUntilExpiry = asset.LifecycleEndDate?.date() != null ? 
                    Date.today().daysBetween(asset.LifecycleEndDate.date()) : null;
                
                enhancedAssets.add(info);
            }
            
            return enhancedAssets;
            
        } catch (Exception e) {
            System.debug('AssetManagementController_Enhanced.getCustomerAssetsWithContact Error: ' + e.getMessage());
            throw new AuraHandledException('Asset 정보를 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description Contact 우선 연락 방법 결정
     * @param contact Contact 정보
     * @return String 우선 연락 방법
     */
    private static String determinePreferredContactMethod(Contact contact) {
        List<String> availableMethods = new List<String>();
        
        if (!contact.HasOptedOutOfEmail && String.isNotBlank(contact.Email)) {
            availableMethods.add('Email (' + contact.Email + ')');
        }
        
        if (!contact.DoNotCall) {
            if (String.isNotBlank(contact.MobilePhone)) {
                availableMethods.add('Mobile (' + contact.MobilePhone + ')');
            }
            if (String.isNotBlank(contact.Phone)) {
                availableMethods.add('Phone (' + contact.Phone + ')');
            }
        }
        
        return availableMethods.isEmpty() ? '연락 불가' : String.join(availableMethods, ', ');
    }
    
    /**
     * @description Asset 생애주기 단계 결정
     * @param asset Asset 정보
     * @return String 생애주기 단계
     */
    private static String determineLifecycleStage(Asset asset) {
        if (asset.LifecycleEndDate == null) {
            return '무기한';
        }
        
        Date endDate = asset.LifecycleEndDate.date();
        Integer daysUntilEnd = Date.today().daysBetween(endDate);
        
        if (daysUntilEnd < 0) {
            return '만료됨';
        } else if (daysUntilEnd <= 30) {
            return '만료 임박';
        } else if (daysUntilEnd <= 90) {
            return '갱신 검토';
        } else if (daysUntilEnd <= 180) {
            return '안정 운영';
        } else {
            return '초기 단계';
        }
    }
    
    /**
     * @description Contact Level별 Asset 분석
     * @param accountId 고객 ID
     * @return Map<String, ContactLevelAnalysis> Level별 분석 결과
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, ContactLevelAnalysis> getAssetAnalyticsByContactLevel(Id accountId) {
        try {
            List<AggregateResult> levelResults = [
                SELECT Contact.Level__c level,
                       COUNT(Id) assetCount,
                       SUM(Price) totalValue,
                       AVG(Price) avgValue
                FROM Asset 
                WHERE AccountId = :accountId
                AND ContactId != null
                AND Contact.Level__c != null
                AND Status = 'Purchased'
                GROUP BY Contact.Level__c
            ];
            
            Map<String, ContactLevelAnalysis> analysisMap = new Map<String, ContactLevelAnalysis>();
            
            for (AggregateResult result : levelResults) {
                ContactLevelAnalysis analysis = new ContactLevelAnalysis();
                analysis.contactLevel = (String)result.get('level');
                analysis.assetCount = (Integer)result.get('assetCount');
                analysis.totalValue = (Decimal)result.get('totalValue');
                analysis.averageValue = (Decimal)result.get('avgValue');
                
                analysisMap.put(analysis.contactLevel, analysis);
            }
            
            return analysisMap;
            
        } catch (Exception e) {
            System.debug('AssetManagementController_Enhanced.getAssetAnalyticsByContactLevel Error: ' + e.getMessage());
            throw new AuraHandledException('Contact Level별 분석 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description 갱신 대상 Contact 우선순위 분석
     * @param monthsAhead 몇 개월 후까지 조회할지
     * @return List<RenewalContactPriority> 우선순위별 Contact 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<RenewalContactPriority> getRenewalContactPriorities(Integer monthsAhead) {
        try {
            Date cutoffDate = Date.today().addMonths(monthsAhead != null ? monthsAhead : 6);
            
            List<Asset> renewalAssets = [
                SELECT Id, Name, SerialNumber, Price, LifecycleEndDate,
                       ContactId, Contact.Name, Contact.Email, Contact.Phone, Contact.MobilePhone,
                       Contact.Level__c, Contact.Department, Contact.Languages__c,
                       Contact.DoNotCall, Contact.HasOptedOutOfEmail,
                       Account.Id, Account.Name, Account.Owner.Name
                FROM Asset 
                WHERE LifecycleEndDate <= :cutoffDate
                AND LifecycleEndDate >= :Date.today()
                AND Status = 'Purchased'
                AND ContactId != null
                ORDER BY Contact.Level__c DESC, LifecycleEndDate ASC
            ];
            
            List<RenewalContactPriority> priorities = new List<RenewalContactPriority>();
            
            for (Asset asset : renewalAssets) {
                RenewalContactPriority priority = new RenewalContactPriority();
                
                // Asset 정보
                priority.assetId = asset.Id;
                priority.assetName = asset.Name;
                priority.orderNumber = asset.SerialNumber;
                priority.assetValue = asset.Price;
                priority.renewalDate = asset.LifecycleEndDate?.date();
                
                // Contact 정보
                priority.contactId = asset.ContactId;
                priority.contactName = asset.Contact.Name;
                priority.contactLevel = asset.Contact.Level__c;
                priority.contactDepartment = asset.Contact.Department;
                priority.contactLanguages = asset.Contact.Languages__c;
                
                // 연락 가능성 및 방법
                priority.canCall = !asset.Contact.DoNotCall;
                priority.canEmail = !asset.Contact.HasOptedOutOfEmail;
                priority.preferredContactMethod = determinePreferredContactMethod(asset.Contact);
                
                // 우선순위 점수 계산
                priority.priorityScore = calculateRenewalPriority(asset);
                priority.priorityReason = generatePriorityReason(asset);
                
                // Account 정보
                priority.accountName = asset.Account.Name;
                priority.accountOwner = asset.Account.Owner.Name;
                
                priorities.add(priority);
            }
            
            return priorities;
            
        } catch (Exception e) {
            System.debug('AssetManagementController_Enhanced.getRenewalContactPriorities Error: ' + e.getMessage());
            throw new AuraHandledException('갱신 우선순위 분석 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description 갱신 우선순위 점수 계산
     * @param asset Asset 정보
     * @return Integer 우선순위 점수 (높을수록 우선)
     */
    private static Integer calculateRenewalPriority(Asset asset) {
        Integer score = 0;
        
        // Asset 가치 점수 (0-30점)
        if (asset.Price != null) {
            if (asset.Price >= 10000000) score += 30;        // 1천만원 이상
            else if (asset.Price >= 5000000) score += 25;    // 500만원 이상
            else if (asset.Price >= 1000000) score += 20;    // 100만원 이상
            else if (asset.Price >= 500000) score += 15;     // 50만원 이상
            else score += 10;
        }
        
        // Contact Level 점수 (0-25점)
        if (asset.Contact?.Level__c != null) {
            switch on asset.Contact.Level__c {
                when 'Primary' { score += 25; }
                when 'Secondary' { score += 20; }
                when 'Tertiary' { score += 15; }
                when else { score += 10; }
            }
        }
        
        // 만료 임박도 점수 (0-25점)
        if (asset.LifecycleEndDate != null) {
            Integer daysUntilExpiry = Date.today().daysBetween(asset.LifecycleEndDate.date());
            if (daysUntilExpiry <= 30) score += 25;          // 30일 이내
            else if (daysUntilExpiry <= 60) score += 20;     // 60일 이내
            else if (daysUntilExpiry <= 90) score += 15;     // 90일 이내
            else if (daysUntilExpiry <= 180) score += 10;    // 180일 이내
            else score += 5;
        }
        
        // 연락 가능성 점수 (0-20점)
        if (asset.Contact != null) {
            if (!asset.Contact.HasOptedOutOfEmail && String.isNotBlank(asset.Contact.Email)) {
                score += 10;
            }
            if (!asset.Contact.DoNotCall && (String.isNotBlank(asset.Contact.Phone) || String.isNotBlank(asset.Contact.MobilePhone))) {
                score += 10;
            }
        }
        
        return score;
    }
    
    /**
     * @description 우선순위 사유 생성
     * @param asset Asset 정보
     * @return String 우선순위 사유
     */
    private static String generatePriorityReason(Asset asset) {
        List<String> reasons = new List<String>();
        
        if (asset.Price != null && asset.Price >= 5000000) {
            reasons.add('고가치 Asset (' + asset.Price.format() + '원)');
        }
        
        if (asset.Contact?.Level__c == 'Primary') {
            reasons.add('주요 연락처 (Primary Level)');
        }
        
        if (asset.LifecycleEndDate != null) {
            Integer daysUntilExpiry = Date.today().daysBetween(asset.LifecycleEndDate.date());
            if (daysUntilExpiry <= 30) {
                reasons.add('만료 임박 (' + daysUntilExpiry + '일 남음)');
            }
        }
        
        Boolean canContact = false;
        if (asset.Contact != null) {
            if (!asset.Contact.HasOptedOutOfEmail && String.isNotBlank(asset.Contact.Email)) {
                canContact = true;
            }
            if (!asset.Contact.DoNotCall && (String.isNotBlank(asset.Contact.Phone) || String.isNotBlank(asset.Contact.MobilePhone))) {
                canContact = true;
            }
        }
        
        if (canContact) {
            reasons.add('연락 가능');
        } else {
            reasons.add('연락 제한');
        }
        
        return reasons.isEmpty() ? '일반' : String.join(reasons, ', ');
    }
    
    // Enhanced Wrapper Classes
    
    /**
     * @description 향상된 Asset 정보 클래스
     */
    public class EnhancedAssetInfo {
        @AuraEnabled public Id assetId { get; set; }
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public String serialNumber { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Date purchaseDate { get; set; }
        @AuraEnabled public Date installDate { get; set; }
        @AuraEnabled public Date lifecycleEndDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal price { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public String description { get; set; }
        
        // Contact 세부 정보
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String contactEmail { get; set; }
        @AuraEnabled public String contactPhone { get; set; }
        @AuraEnabled public String contactMobile { get; set; }
        @AuraEnabled public String contactDepartment { get; set; }
        @AuraEnabled public String contactLevel { get; set; }
        @AuraEnabled public String contactLanguages { get; set; }
        @AuraEnabled public String contactLeadSource { get; set; }
        @AuraEnabled public Boolean canCall { get; set; }
        @AuraEnabled public Boolean canEmail { get; set; }
        @AuraEnabled public String preferredContactMethod { get; set; }
        
        // 분석 정보
        @AuraEnabled public String lifecycleStage { get; set; }
        @AuraEnabled public Integer daysUntilExpiry { get; set; }
    }
    
    /**
     * @description Contact Level별 분석 클래스
     */
    public class ContactLevelAnalysis {
        @AuraEnabled public String contactLevel { get; set; }
        @AuraEnabled public Integer assetCount { get; set; }
        @AuraEnabled public Decimal totalValue { get; set; }
        @AuraEnabled public Decimal averageValue { get; set; }
    }
    
    /**
     * @description 갱신 Contact 우선순위 클래스
     */
    public class RenewalContactPriority {
        @AuraEnabled public Id assetId { get; set; }
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public Decimal assetValue { get; set; }
        @AuraEnabled public Date renewalDate { get; set; }
        
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String contactLevel { get; set; }
        @AuraEnabled public String contactDepartment { get; set; }
        @AuraEnabled public String contactLanguages { get; set; }
        
        @AuraEnabled public Boolean canCall { get; set; }
        @AuraEnabled public Boolean canEmail { get; set; }
        @AuraEnabled public String preferredContactMethod { get; set; }
        
        @AuraEnabled public Integer priorityScore { get; set; }
        @AuraEnabled public String priorityReason { get; set; }
        
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String accountOwner { get; set; }
    }
}

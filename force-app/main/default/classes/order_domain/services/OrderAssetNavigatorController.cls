/**
 * @description OrderAssetNavigator 컴포넌트를 위한 컨트롤러
 * Order에서 연결된 Asset 정보와 납부 상태를 조회하고 관리
 * @author JH Moon
 * @since 2025-07-22
 */
public with sharing class OrderAssetNavigatorController {
    
    /**
     * @description Order의 Asset 정보와 납부 요약 정보를 조회
     * @param orderId Order ID
     * @return OrderAssetInfo 래퍼 클래스
     */
    @AuraEnabled(cacheable=true)
    public static OrderAssetInfo getOrderAssetInfo(Id orderId) {
        try {
            OrderAssetInfo result = new OrderAssetInfo();
            
            // Order 정보 조회 (OrderItem 포함)
            Order orderInfo = [
                SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount, 
                       Status, EffectiveDate, EndDate, CreatedDate,
                       (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice, ListPrice
                        FROM OrderItems 
                        ORDER BY CreatedDate DESC 
                        LIMIT 1)
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // Order와 연결된 Asset 조회 (SerialNumber 기준)
            List<Asset> assets = [
                SELECT Id, Name, SerialNumber, Status, ContactId, AccountId,
                       PurchaseDate, InstallDate, UsageEndDate, Description,
                       Product2Id, Product2.Name, CreatedDate
                FROM Asset 
                WHERE SerialNumber = :orderInfo.OrderNumber
                AND AccountId = :orderInfo.AccountId
                LIMIT 1
            ];
            
            // Asset 정보 설정
            if (!assets.isEmpty()) {
                result.assetInfo = assets[0];
            }
            
            // Order 정보 설정 (OrderItem 포함)
            result.orderInfo = orderInfo;
            
            // PaymentStatus 요약 정보 계산
            result.paymentSummary = calculatePaymentSummary(orderId);
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Order Asset 정보 조회 중 오류: ' + e.getMessage());
        }
    }
    
    /**
     * @description Order에서 Asset을 수동으로 생성
     * @param orderId Order ID
     * @return AssetCreationResult 래퍼 클래스
     */
    @AuraEnabled
    public static AssetCreationResult createAssetFromOrder(Id orderId) {
        try {
            AssetCreationResult result = new AssetCreationResult();
            
            // 완납 상태 확인
            PaymentSummary summary = calculatePaymentSummary(orderId);
            if (!summary.isFullyPaid) {
                result.success = false;
                result.message = '모든 납부가 완료되지 않아 Asset을 생성할 수 없습니다.';
                return result;
            }
            
            // 이미 Asset이 존재하는지 확인
            Order orderInfo = [SELECT OrderNumber, AccountId FROM Order WHERE Id = :orderId];
            List<Asset> existingAssets = [
                SELECT Id FROM Asset 
                WHERE SerialNumber = :orderInfo.OrderNumber 
                AND AccountId = :orderInfo.AccountId
            ];
            
            if (!existingAssets.isEmpty()) {
                result.success = false;
                result.message = '이미 해당 Order에 대한 Asset이 존재합니다.';
                result.assetId = existingAssets[0].Id;
                return result;
            }
            
            // AccountBasedAssetService를 통한 Asset 생성
            try {
                Asset newAsset = AccountBasedAssetService.createAssetWithAccountAnalysis(orderId);
                
                result.success = true;
                result.message = 'Asset이 성공적으로 생성되었습니다.';
                result.assetId = newAsset.Id;
                
                // 생성 성공 로그
                System.debug('Asset 생성 성공: Order ' + orderId + ' -> Asset ' + newAsset.Id);
                
            } catch (Exception assetCreationError) {
                result.success = false;
                result.message = 'Asset 생성 중 오류: ' + assetCreationError.getMessage();
                System.debug('Asset 생성 실패: ' + assetCreationError.getMessage());
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Asset 생성 중 오류: ' + e.getMessage());
        }
    }
    
    /**
     * @description 특정 Order의 납부 요약 정보를 계산
     * @param orderId Order ID
     * @return PaymentSummary 래퍼 클래스
     */
    private static PaymentSummary calculatePaymentSummary(Id orderId) {
        PaymentSummary summary = new PaymentSummary();
        
        // PaymentStatus 목록 조회
        List<PaymentStatus__c> paymentStatuses = [
            SELECT Id, Status__c, Amount__c, Installment_Number__c, DueDate__c
            FROM PaymentStatus__c 
            WHERE Order__c = :orderId 
            ORDER BY Installment_Number__c
        ];
        
        if (paymentStatuses.isEmpty()) {
            // PaymentStatus가 없는 경우 기본값 설정
            summary.totalPayments = 0;
            summary.completedPayments = 0;
            summary.remainingPayments = 0;
            summary.isFullyPaid = false;
            summary.totalAmount = 0;
            return summary;
        }
        
        // 납부 통계 계산
        Integer completedCount = 0;
        Decimal totalAmountValue = 0;
        Date today = Date.today();
        
        for (PaymentStatus__c payment : paymentStatuses) {
            if (payment.Status__c == '완납') {
                completedCount++;
            }
            if (payment.Amount__c != null) {
                totalAmountValue += payment.Amount__c;
            }
        }
        
        summary.totalPayments = paymentStatuses.size();
        summary.completedPayments = completedCount;
        summary.remainingPayments = summary.totalPayments - completedCount;
        summary.isFullyPaid = (completedCount == paymentStatuses.size() && paymentStatuses.size() > 0);
        summary.totalAmount = totalAmountValue;
        
        return summary;
    }
    
    /**
     * @description 통화 포맷
     */
    private static String formatCurrency(Decimal amount) {
        if (amount == null) return '₩0';
        return '₩' + amount.format();
    }
    
    /**
     * @description Order Asset 정보 래퍼 클래스
     */
    public class OrderAssetInfo {
        @AuraEnabled public Asset assetInfo { get; set; }
        @AuraEnabled public Order orderInfo { get; set; }
        @AuraEnabled public PaymentSummary paymentSummary { get; set; }
        
        public OrderAssetInfo() {
            this.assetInfo = null;
            this.orderInfo = null;
            this.paymentSummary = new PaymentSummary();
        }
    }
    
    /**
     * @description 납부 요약 정보 래퍼 클래스
     */
    public class PaymentSummary {
        @AuraEnabled public Integer totalPayments { get; set; }
        @AuraEnabled public Integer completedPayments { get; set; }
        @AuraEnabled public Integer remainingPayments { get; set; }
        @AuraEnabled public Boolean isFullyPaid { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        
        public PaymentSummary() {
            this.totalPayments = 0;
            this.completedPayments = 0;
            this.remainingPayments = 0;
            this.isFullyPaid = false;
            this.totalAmount = 0;
        }
    }
    
    /**
     * @description Asset 생성 결과 래퍼 클래스
     */
    public class AssetCreationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id assetId { get; set; }
        
        public AssetCreationResult() {
            this.success = false;
            this.message = '';
            this.assetId = null;
        }
    }
}

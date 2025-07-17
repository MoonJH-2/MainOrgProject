/**
 * @description       : 
 * @author            : JH Moon
 * @last modified on  : 07-14-2025
 * @last modified by  : JH Moon
**/
public with sharing class PaymentStatusPDFController {
    public Order orderInfo { get; set; }
    public List<PaymentStatus__c> paymentStatuses { get; set; }
    public Integer totalInstallments { get; set; }
    public Integer completedInstallments { get; set; }
    public Decimal progressPercentage { get; set; }
    
    public PaymentStatusPDFController() {
        String orderId = ApexPages.currentPage().getParameters().get('orderId');
        
        if (String.isNotBlank(orderId)) {
            loadPaymentData(orderId);
        }
    }
    
    private void loadPaymentData(String orderId) {
        try {
            // Order 정보 조회
            orderInfo = [
                SELECT Id, OrderNumber, TotalAmount, EffectiveDate, Payment_Method__c, Account.Name
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // PaymentStatus 목록 조회
            paymentStatuses = [
                SELECT Id, Order__c, Amount__c, DueDate__c, InstallmentNumber__c, Status__c, PaidDate__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId 
                ORDER BY InstallmentNumber__c ASC
            ];
            
            // 통계 계산
            totalInstallments = paymentStatuses.size();
            completedInstallments = 0;
            
            for (PaymentStatus__c ps : paymentStatuses) {
                if (ps.Status__c == '완납') {
                    completedInstallments++;
                }
            }
            
            progressPercentage = totalInstallments > 0 ? 
                (Decimal.valueOf(completedInstallments) / totalInstallments * 100).setScale(1) : 0;
                
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                '데이터를 가져오는 중 오류가 발생했습니다: ' + e.getMessage()));
        }
    }
}

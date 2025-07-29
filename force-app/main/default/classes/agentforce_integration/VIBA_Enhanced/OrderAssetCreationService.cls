/**
 * @description Order Asset Creation Service - 단순화된 버전
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */
public with sharing class OrderAssetCreationService {
    
    public static Asset createAssetFromOrder(Order order, PaymentStatus__c paymentStatus) {
        Asset newAsset = new Asset();
        newAsset.Name = order.OrderNumber + ' - Asset';
        newAsset.AccountId = order.AccountId;
        newAsset.Status = 'Purchased';
        newAsset.PurchaseDate = Date.today();
        
        return newAsset;
    }
    
    public static void processAssetCreation(List<PaymentStatus__c> completedPayments) {
        List<Asset> assetsToCreate = new List<Asset>();
        
        for (PaymentStatus__c payment : completedPayments) {
            if (payment.Status__c == '완납' && payment.Order__c != null) {
                // Order 정보 조회
                List<Order> orders = [
                    SELECT Id, OrderNumber, AccountId 
                    FROM Order 
                    WHERE Id = :payment.Order__c 
                    LIMIT 1
                ];
                
                if (!orders.isEmpty()) {
                    Asset newAsset = createAssetFromOrder(orders[0], payment);
                    assetsToCreate.add(newAsset);
                }
            }
        }
        
        if (!assetsToCreate.isEmpty()) {
            try {
                insert assetsToCreate;
                System.debug('✅ Asset 생성 완료: ' + assetsToCreate.size() + '개');
            } catch (Exception e) {
                System.debug('❌ Asset 생성 오류: ' + e.getMessage());
            }
        }
    }
}

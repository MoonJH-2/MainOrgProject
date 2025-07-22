/**
 * @description Order에 Opportunity Product를 자동으로 등록하는 서비스
 * @author Moon JeongHyeon
 * @date 2025-07-21
 */
public class OrderProductAutoRegistrationService {
    
    /**
     * @description 단일 Order에 대해 Opportunity Product 자동 등록
     * @param orderId Order ID
     */
    public static void registerOpportunityProducts(Id orderId) {
        try {
            // Order 정보 조회
            Order orderInfo = [
                SELECT Id, OrderNumber, OpportunityId, TotalAmount, 
                       AccountId, Status, Pricebook2Id
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            if (orderInfo.OpportunityId == null) {
                System.debug('Order에 연결된 Opportunity가 없습니다: ' + orderInfo.OrderNumber);
                return;
            }
            
            // 이미 Order Products가 있는지 확인
            List<OrderItem> existingProducts = [
                SELECT Id FROM OrderItem WHERE OrderId = :orderId
            ];
            
            boolean hasProducts = !existingProducts.isEmpty();
            
            if (!hasProducts) {
                // Opportunity Products 조회
                List<OpportunityLineItem> oppProducts = [
                    SELECT Id, Product2Id, Quantity, UnitPrice, TotalPrice,
                           Product2.Name, Product2.ProductCode
                    FROM OpportunityLineItem 
                    WHERE OpportunityId = :orderInfo.OpportunityId
                ];
                
                if (oppProducts.isEmpty()) {
                    System.debug('연결된 Opportunity Products가 없습니다: ' + orderInfo.OrderNumber);
                    return;
                }
                
                // Standard Pricebook 설정
                setupPricebook(orderInfo);
                
                // Order Products 생성
                createOrderProducts(orderInfo, oppProducts);
                hasProducts = true;
            }
            
            // Order Products가 있고 Status가 Draft인 경우 Activated로 변경
            if (hasProducts && orderInfo.Status == 'Draft') {
                activateOrder(orderId);
            }
            
            // PaymentStatus 생성 (Order가 Activated 상태가 된 후)
            Order updatedOrder = [SELECT Status FROM Order WHERE Id = :orderId LIMIT 1];
            if (updatedOrder.Status == 'Activated') {
                createPaymentStatusIfNeeded(orderId);
            }
            
            System.debug('Order Product 자동 등록 완료: ' + orderInfo.OrderNumber);
            
        } catch (Exception e) {
            System.debug('Order Product 자동 등록 실패: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description 여러 Order에 대해 일괄 Opportunity Product 등록
     * @param orderIds Order ID 목록
     */
    public static void batchRegisterOpportunityProducts(List<Id> orderIds) {
        for (Id orderId : orderIds) {
            try {
                registerOpportunityProducts(orderId);
            } catch (Exception e) {
                System.debug('Order ID ' + orderId + ' 처리 실패: ' + e.getMessage());
                // 다른 Order 처리를 위해 계속 진행
            }
        }
    }
    
    /**
     * @description Order에 Pricebook 설정
     */
    private static void setupPricebook(Order orderInfo) {
        if (orderInfo.Pricebook2Id != null) {
            return; // 이미 설정됨
        }
        
        // Standard Pricebook 조회
        List<Pricebook2> standardPricebooks = [
            SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1
        ];
        
        if (standardPricebooks.isEmpty()) {
            throw new OrderProductException('Standard Pricebook을 찾을 수 없습니다.');
        }
        
        // Order에 Pricebook 설정
        orderInfo.Pricebook2Id = standardPricebooks[0].Id;
        update orderInfo;
    }
    
    /**
     * @description Opportunity Product를 기반으로 Order Product 생성
     */
    private static void createOrderProducts(Order orderInfo, List<OpportunityLineItem> oppProducts) {
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        for (OpportunityLineItem oppItem : oppProducts) {
            // PricebookEntry 조회/생성
            Id pricebookEntryId = getOrCreatePricebookEntry(
                oppItem.Product2Id, 
                standardPricebook.Id, 
                oppItem.UnitPrice
            );
            
            // OrderItem 생성
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = orderInfo.Id;
            orderItem.Product2Id = oppItem.Product2Id;
            orderItem.PricebookEntryId = pricebookEntryId;
            orderItem.Quantity = oppItem.Quantity;
            orderItem.UnitPrice = oppItem.UnitPrice;
            
            orderItemsToInsert.add(orderItem);
        }
        
        if (!orderItemsToInsert.isEmpty()) {
            insert orderItemsToInsert;
            System.debug('Order Products 생성 완료: ' + orderItemsToInsert.size() + '개');
        }
    }
    
    /**
     * @description PricebookEntry 조회 또는 생성
     */
    private static Id getOrCreatePricebookEntry(Id productId, Id pricebookId, Decimal unitPrice) {
        // 기존 PricebookEntry 조회
        List<PricebookEntry> existingEntries = [
            SELECT Id FROM PricebookEntry 
            WHERE Product2Id = :productId 
            AND Pricebook2Id = :pricebookId
            AND IsActive = true
            LIMIT 1
        ];
        
        if (!existingEntries.isEmpty()) {
            return existingEntries[0].Id;
        }
        
        // 새 PricebookEntry 생성
        PricebookEntry newEntry = new PricebookEntry();
        newEntry.Product2Id = productId;
        newEntry.Pricebook2Id = pricebookId;
        newEntry.UnitPrice = unitPrice;
        newEntry.IsActive = true;
        
        insert newEntry;
        return newEntry.Id;
    }
    
    /**
     * @description 필요한 경우 PaymentStatus 생성
     */
    private static void createPaymentStatusIfNeeded(Id orderId) {
        // 기존 PaymentStatus 확인
        List<PaymentStatus__c> existingPayments = [
            SELECT Id FROM PaymentStatus__c WHERE Order__c = :orderId LIMIT 1
        ];
        
        if (!existingPayments.isEmpty()) {
            return; // 이미 존재함
        }
        
        // Order 정보 다시 조회 (TotalAmount 업데이트 확인)
        Order updatedOrder = [
            SELECT Id, TotalAmount FROM Order WHERE Id = :orderId LIMIT 1
        ];
        
        if (updatedOrder.TotalAmount != null && updatedOrder.TotalAmount > 0) {
            try {
                PaymentScheduleService.createPaymentSchedule(orderId, updatedOrder.TotalAmount);
                System.debug('PaymentStatus 자동 생성 완료');
            } catch (Exception e) {
                System.debug('PaymentStatus 생성 실패: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Order를 Activated 상태로 변경
     */
    private static void activateOrder(Id orderId) {
        try {
            Order orderToActivate = new Order();
            orderToActivate.Id = orderId;
            orderToActivate.Status = 'Activated';
            
            update orderToActivate;
            System.debug('Order 상태 변경: Draft → Activated');
            
        } catch (Exception e) {
            System.debug('Order 활성화 실패: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Custom Exception 클래스
     */
    public class OrderProductException extends Exception {}
}

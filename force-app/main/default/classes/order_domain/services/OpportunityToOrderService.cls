/**
 * @description Opportunity에서 Order로 전환하면서 Opportunity Product를 Order Product로 자동 생성하는 서비스
 * @author Moon JeongHyeon
 * @date 2025-07-21
 */
public class OpportunityToOrderService {
    
    /**
     * @description Opportunity 목록에 대해 Order와 Order Product를 생성
     * @param opportunities Closed Won으로 변경된 Opportunity 목록
     */
    public static void createOrdersWithProducts(List<Opportunity> opportunities) {
        List<Order> ordersToInsert = new List<Order>();
        Map<Id, List<OpportunityLineItem>> oppProductsMap = new Map<Id, List<OpportunityLineItem>>();
        
        // 1. Opportunity Product 조회
        List<OpportunityLineItem> oppProducts = [
            SELECT Id, OpportunityId, Product2Id, Quantity, UnitPrice, TotalPrice,
                   Product2.Name, Product2.ProductCode
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :opportunities
        ];
        
        // 2. Opportunity별 Product 그룹핑
        for (OpportunityLineItem item : oppProducts) {
            if (!oppProductsMap.containsKey(item.OpportunityId)) {
                oppProductsMap.put(item.OpportunityId, new List<OpportunityLineItem>());
            }
            oppProductsMap.get(item.OpportunityId).add(item);
        }
        
        // 3. Order 생성
        for (Opportunity opp : opportunities) {
            Order newOrder = new Order();
            newOrder.AccountId = opp.AccountId;
            newOrder.OpportunityId = opp.Id;
            newOrder.Name = opp.Name;
            newOrder.Status = 'Draft';
            newOrder.EffectiveDate = Date.today();
            
            // Pricebook2 설정 (Standard Price Book)
            List<Pricebook2> standardPricebooks = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            if (!standardPricebooks.isEmpty()) {
                newOrder.Pricebook2Id = standardPricebooks[0].Id;
            }
            
            ordersToInsert.add(newOrder);
        }
        
        // 4. Order 생성
        if (!ordersToInsert.isEmpty()) {
            insert ordersToInsert;
            
            // 5. Order Product 생성
            createOrderProducts(ordersToInsert, oppProductsMap);
            
            // 6. Order를 Activated 상태로 변경하여 TotalAmount 자동 계산되도록 함
            List<Order> ordersToActivate = new List<Order>();
            for (Order ord : ordersToInsert) {
                ord.Status = 'Activated';
                ordersToActivate.add(ord);
            }
            update ordersToActivate;
            
            // 7. PaymentStatus 생성 (Order가 Activated된 후)
            regeneratePaymentStatus(ordersToActivate);
        }
    }
    
    /**
     * @description Order에 대한 Order Product 생성
     * @param orders 생성된 Order 목록
     * @param oppProductsMap Opportunity Product 맵
     */
    private static void createOrderProducts(List<Order> orders, Map<Id, List<OpportunityLineItem>> oppProductsMap) {
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        
        // PriceBook 조회 (Standard Price Book 사용)
        List<Pricebook2> standardPricebooks = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (standardPricebooks.isEmpty()) {
            System.debug('Standard Price Book을 찾을 수 없습니다.');
            return;
        }
        
        Pricebook2 standardPricebook = standardPricebooks[0];
        
        for (Order ord : orders) {
            if (oppProductsMap.containsKey(ord.OpportunityId)) {
                for (OpportunityLineItem oppItem : oppProductsMap.get(ord.OpportunityId)) {
                    
                    // PricebookEntry 조회/생성
                    List<PricebookEntry> pbeList = [
                        SELECT Id FROM PricebookEntry 
                        WHERE Product2Id = :oppItem.Product2Id 
                        AND Pricebook2Id = :standardPricebook.Id
                        LIMIT 1
                    ];
                    
                    Id pricebookEntryId;
                    if (pbeList.isEmpty()) {
                        // PricebookEntry가 없으면 생성
                        try {
                            PricebookEntry newPbe = new PricebookEntry();
                            newPbe.Product2Id = oppItem.Product2Id;
                            newPbe.Pricebook2Id = standardPricebook.Id;
                            newPbe.UnitPrice = oppItem.UnitPrice;
                            newPbe.IsActive = true;
                            insert newPbe;
                            pricebookEntryId = newPbe.Id;
                        } catch (Exception e) {
                            System.debug('PricebookEntry 생성 실패: ' + e.getMessage());
                            continue;
                        }
                    } else {
                        pricebookEntryId = pbeList[0].Id;
                    }
                    
                    // OrderItem 생성
                    OrderItem orderItem = new OrderItem();
                    orderItem.OrderId = ord.Id;
                    orderItem.Product2Id = oppItem.Product2Id;
                    orderItem.PricebookEntryId = pricebookEntryId;
                    orderItem.Quantity = oppItem.Quantity;
                    orderItem.UnitPrice = oppItem.UnitPrice;
                    
                    orderItemsToInsert.add(orderItem);
                }
            }
        }
        
        if (!orderItemsToInsert.isEmpty()) {
            try {
                insert orderItemsToInsert;
                System.debug('Order Products 생성 완료: ' + orderItemsToInsert.size() + '개');
            } catch (Exception e) {
                System.debug('Order Products 생성 실패: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Order에 대한 PaymentStatus 재생성
     * @param orders Order 목록
     */
    private static void regeneratePaymentStatus(List<Order> orders) {
        // 기존 PaymentStatus 삭제
        List<PaymentStatus__c> existingPayments = [
            SELECT Id FROM PaymentStatus__c 
            WHERE Order__c IN :orders
        ];
        
        if (!existingPayments.isEmpty()) {
            try {
                delete existingPayments;
            } catch (Exception e) {
                System.debug('기존 PaymentStatus 삭제 실패: ' + e.getMessage());
            }
        }
        
        // Order의 TotalAmount를 다시 조회하여 PaymentStatus 생성
        List<Order> refreshedOrders = [
            SELECT Id, TotalAmount FROM Order WHERE Id IN :orders
        ];
        
        for (Order ord : refreshedOrders) {
            if (ord.TotalAmount != null && ord.TotalAmount > 0) {
                try {
                    PaymentScheduleService.createPaymentSchedule(ord.Id, ord.TotalAmount);
                } catch (Exception e) {
                    System.debug('PaymentStatus 생성 실패: ' + e.getMessage());
                }
            }
        }
    }
}

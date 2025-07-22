/**
 * @description Order Product가 누락된 기존 Order들을 보정하는 배치 클래스
 * @author Moon JeongHyeon
 * @date 2025-07-21
 */
public class OrderProductCorrectionBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Order Product가 없는 Order 조회
        return Database.getQueryLocator([
            SELECT Id, OpportunityId, TotalAmount, AccountId
            FROM Order 
            WHERE OpportunityId != null
            AND Id NOT IN (SELECT OrderId FROM OrderItem WHERE OrderId != null)
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Order> orders) {
        try {
            Set<Id> opportunityIds = new Set<Id>();
            for (Order ord : orders) {
                if (ord.OpportunityId != null) {
                    opportunityIds.add(ord.OpportunityId);
                }
            }
            
            if (opportunityIds.isEmpty()) {
                return;
            }
            
            // Opportunity Product 조회
            Map<Id, List<OpportunityLineItem>> oppProductsMap = new Map<Id, List<OpportunityLineItem>>();
            List<OpportunityLineItem> oppProducts = [
                SELECT Id, OpportunityId, Product2Id, Quantity, UnitPrice, TotalPrice,
                       Product2.Name, Product2.ProductCode
                FROM OpportunityLineItem 
                WHERE OpportunityId IN :opportunityIds
            ];
            
            for (OpportunityLineItem item : oppProducts) {
                if (!oppProductsMap.containsKey(item.OpportunityId)) {
                    oppProductsMap.put(item.OpportunityId, new List<OpportunityLineItem>());
                }
                oppProductsMap.get(item.OpportunityId).add(item);
            }
            
            // Order Product 생성 및 Order 상태 변경
            List<Order> ordersToUpdate = new List<Order>();
            List<OrderItem> orderItemsToInsert = new List<OrderItem>();
            
            List<Pricebook2> standardPricebooks = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            if (standardPricebooks.isEmpty()) {
                System.debug('Standard Price Book을 찾을 수 없습니다.');
                return;
            }
            
            Pricebook2 standardPricebook = standardPricebooks[0];
            
            for (Order ord : orders) {
                if (oppProductsMap.containsKey(ord.OpportunityId)) {
                    
                    // Pricebook2 설정
                    if (ord.Pricebook2Id == null) {
                        ord.Pricebook2Id = standardPricebook.Id;
                        ordersToUpdate.add(ord);
                    }
                    
                    for (OpportunityLineItem oppItem : oppProductsMap.get(ord.OpportunityId)) {
                        
                        // PricebookEntry 처리
                        List<PricebookEntry> pbeList = [
                            SELECT Id FROM PricebookEntry 
                            WHERE Product2Id = :oppItem.Product2Id 
                            AND Pricebook2Id = :standardPricebook.Id
                            LIMIT 1
                        ];
                        
                        Id pricebookEntryId;
                        if (pbeList.isEmpty()) {
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
            
            // 데이터 업데이트
            if (!ordersToUpdate.isEmpty()) {
                try {
                    update ordersToUpdate;
                    System.debug('Order Pricebook2 설정 완료: ' + ordersToUpdate.size() + '개');
                } catch (Exception e) {
                    System.debug('Order 업데이트 실패: ' + e.getMessage());
                }
            }
            
            if (!orderItemsToInsert.isEmpty()) {
                try {
                    insert orderItemsToInsert;
                    System.debug('Order Products 생성 완료: ' + orderItemsToInsert.size() + '개');
                    
                    // Order Products 생성 후 PaymentStatus 재생성
                    regeneratePaymentStatusForOrders(orders);
                } catch (Exception e) {
                    System.debug('Order Products 생성 실패: ' + e.getMessage());
                }
            }
            
        } catch (Exception e) {
            System.debug('OrderProductCorrectionBatch 실행 오류: ' + e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext context) {
        System.debug('OrderProductCorrectionBatch 완료');
    }
    
    /**
     * @description Order에 대한 PaymentStatus 재생성
     * @param orders Order 목록
     */
    private void regeneratePaymentStatusForOrders(List<Order> orders) {
        // 기존 PaymentStatus 삭제
        List<PaymentStatus__c> existingPayments = [
            SELECT Id FROM PaymentStatus__c 
            WHERE Order__c IN :orders
        ];
        
        if (!existingPayments.isEmpty()) {
            try {
                delete existingPayments;
                System.debug('기존 PaymentStatus 삭제 완료: ' + existingPayments.size() + '개');
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
                    System.debug('PaymentStatus 생성 실패 (Order ID: ' + ord.Id + '): ' + e.getMessage());
                }
            }
        }
    }
}

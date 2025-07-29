# 📋 Opportunity Product → Order Product 자동 전환 설계안

## 🎯 목표
Opportunity에서 Order로 전환 시 Opportunity Product가 자동으로 Order Product로 생성되도록 설계

## 📊 현재 상황 분석

### 문제 상황
```
Opportunity Product:
- 제품: 카셰어링 플래티넘(PLATINUM)
- 수량: 100개
- 단가: ₩127,200
- 총액: ₩10,176,000

Order:
- 주문번호: 00000137
- 총액: ₩1,590,000 ❌ (불일치)
- Order Product: 없음 ❌

PaymentStatus:
- 1차: ₩1,590,000 (Order 금액 기준으로 생성됨)
```

### 근본 원인
1. **수동 Order 생성**: Opportunity Product 정보가 전달되지 않음
2. **Price 불일치**: Order Amount와 Opportunity Product Total이 다름
3. **Product 정보 누락**: Order에 연결된 제품 정보 없음

## 🚀 해결 방안

### Phase 1: Order 생성 시 자동화

#### 1.1 OpportunityTrigger 구현
```apex
// OpportunityTrigger.trigger
trigger OpportunityTrigger on Opportunity (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Opportunity> closedWonOpps = new List<Opportunity>();
        
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            
            // StageName이 Closed Won으로 변경된 경우
            if (oldOpp.StageName != 'Closed Won' && opp.StageName == 'Closed Won') {
                closedWonOpps.add(opp);
            }
        }
        
        if (!closedWonOpps.isEmpty()) {
            OpportunityToOrderService.createOrdersWithProducts(closedWonOpps);
        }
    }
}
```

#### 1.2 OpportunityToOrderService 클래스
```apex
public class OpportunityToOrderService {
    
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
            
            // Opportunity Product 총액으로 Order Amount 설정
            if (oppProductsMap.containsKey(opp.Id)) {
                Decimal totalAmount = 0;
                for (OpportunityLineItem item : oppProductsMap.get(opp.Id)) {
                    totalAmount += item.TotalPrice;
                }
                newOrder.TotalAmount = totalAmount;
            }
            
            ordersToInsert.add(newOrder);
        }
        
        // 4. Order 생성
        insert ordersToInsert;
        
        // 5. Order Product 생성
        createOrderProducts(ordersToInsert, oppProductsMap);
        
        // 6. PaymentStatus 재생성 (정확한 금액으로)
        regeneratePaymentStatus(ordersToInsert);
    }
    
    private static void createOrderProducts(List<Order> orders, Map<Id, List<OpportunityLineItem>> oppProductsMap) {
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        
        // PriceBook 조회 (Standard Price Book 사용)
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
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
                        PricebookEntry newPbe = new PricebookEntry();
                        newPbe.Product2Id = oppItem.Product2Id;
                        newPbe.Pricebook2Id = standardPricebook.Id;
                        newPbe.UnitPrice = oppItem.UnitPrice;
                        newPbe.IsActive = true;
                        insert newPbe;
                        pricebookEntryId = newPbe.Id;
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
            insert orderItemsToInsert;
        }
    }
    
    private static void regeneratePaymentStatus(List<Order> orders) {
        // 기존 PaymentStatus 삭제
        List<PaymentStatus__c> existingPayments = [
            SELECT Id FROM PaymentStatus__c 
            WHERE Order__c IN :orders
        ];
        
        if (!existingPayments.isEmpty()) {
            delete existingPayments;
        }
        
        // 정확한 금액으로 PaymentStatus 재생성
        for (Order ord : orders) {
            if (ord.TotalAmount != null && ord.TotalAmount > 0) {
                PaymentScheduleService.createPaymentSchedule(ord.Id, ord.TotalAmount);
            }
        }
    }
}
```

### Phase 2: 기존 Order 보정

#### 2.1 OrderProductCorrection 배치 클래스
```apex
public class OrderProductCorrectionBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Order Product가 없는 Order 조회
        return Database.getQueryLocator([
            SELECT Id, OpportunityId, TotalAmount, AccountId
            FROM Order 
            WHERE OpportunityId != null
            AND Id NOT IN (SELECT OrderId FROM OrderItem)
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Order> orders) {
        try {
            Set<Id> opportunityIds = new Set<Id>();
            for (Order ord : orders) {
                opportunityIds.add(ord.OpportunityId);
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
            
            // Order Product 생성 및 Order Amount 보정
            List<Order> ordersToUpdate = new List<Order>();
            List<OrderItem> orderItemsToInsert = new List<OrderItem>();
            
            Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            
            for (Order ord : orders) {
                if (oppProductsMap.containsKey(ord.OpportunityId)) {
                    Decimal correctTotalAmount = 0;
                    
                    for (OpportunityLineItem oppItem : oppProductsMap.get(ord.OpportunityId)) {
                        correctTotalAmount += oppItem.TotalPrice;
                        
                        // PricebookEntry 처리
                        List<PricebookEntry> pbeList = [
                            SELECT Id FROM PricebookEntry 
                            WHERE Product2Id = :oppItem.Product2Id 
                            AND Pricebook2Id = :standardPricebook.Id
                            LIMIT 1
                        ];
                        
                        Id pricebookEntryId;
                        if (pbeList.isEmpty()) {
                            PricebookEntry newPbe = new PricebookEntry();
                            newPbe.Product2Id = oppItem.Product2Id;
                            newPbe.Pricebook2Id = standardPricebook.Id;
                            newPbe.UnitPrice = oppItem.UnitPrice;
                            newPbe.IsActive = true;
                            insert newPbe;
                            pricebookEntryId = newPbe.Id;
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
                    
                    // Order Amount 보정
                    if (ord.TotalAmount != correctTotalAmount) {
                        ord.TotalAmount = correctTotalAmount;
                        ordersToUpdate.add(ord);
                    }
                }
            }
            
            // 데이터 업데이트
            if (!orderItemsToInsert.isEmpty()) {
                insert orderItemsToInsert;
            }
            
            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
                
                // PaymentStatus 재생성
                regeneratePaymentStatusForOrders(ordersToUpdate);
            }
            
        } catch (Exception e) {
            System.debug('OrderProductCorrectionBatch 오류: ' + e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext context) {
        System.debug('OrderProductCorrectionBatch 완료');
    }
    
    private void regeneratePaymentStatusForOrders(List<Order> orders) {
        // 기존 PaymentStatus 삭제
        List<PaymentStatus__c> existingPayments = [
            SELECT Id FROM PaymentStatus__c 
            WHERE Order__c IN :orders
        ];
        
        if (!existingPayments.isEmpty()) {
            delete existingPayments;
        }
        
        // 정확한 금액으로 PaymentStatus 재생성
        for (Order ord : orders) {
            if (ord.TotalAmount != null && ord.TotalAmount > 0) {
                PaymentScheduleService.createPaymentSchedule(ord.Id, ord.TotalAmount);
            }
        }
    }
}
```

### Phase 3: PaymentScheduleService 개선

#### 3.1 PaymentScheduleService 클래스
```apex
public class PaymentScheduleService {
    
    public static void createPaymentSchedule(Id orderId, Decimal totalAmount) {
        // Order 정보 조회
        Order orderInfo = [
            SELECT Id, Payment_Method__c, EffectiveDate 
            FROM Order 
            WHERE Id = :orderId 
            LIMIT 1
        ];
        
        List<PaymentStatus__c> paymentStatuses = new List<PaymentStatus__c>();
        
        if (orderInfo.Payment_Method__c == '년별') {
            // 연간 일시납
            PaymentStatus__c payment = new PaymentStatus__c();
            payment.Order__c = orderId;
            payment.Amount__c = totalAmount;
            payment.DueDate__c = orderInfo.EffectiveDate;
            payment.Status__c = '미납';
            payment.InstallmentNumber__c = 1;
            
            paymentStatuses.add(payment);
            
        } else if (orderInfo.Payment_Method__c == '분기별') {
            // 분기별 4회 분할
            Decimal quarterlyAmount = totalAmount / 4;
            Date baseDate = orderInfo.EffectiveDate;
            
            for (Integer i = 0; i < 4; i++) {
                PaymentStatus__c payment = new PaymentStatus__c();
                payment.Order__c = orderId;
                payment.Amount__c = quarterlyAmount;
                payment.DueDate__c = baseDate.addMonths(i * 3);
                payment.Status__c = '미납';
                payment.InstallmentNumber__c = i + 1;
                
                paymentStatuses.add(payment);
            }
        }
        
        if (!paymentStatuses.isEmpty()) {
            insert paymentStatuses;
        }
    }
}
```

## 🚀 실행 계획

### 즉시 실행 (Order 00000137 보정)
```apex
// Developer Console에서 실행
Order targetOrder = [SELECT Id, OpportunityId, TotalAmount FROM Order WHERE OrderNumber = '00000137'];
List<Order> ordersToFix = new List<Order>{ targetOrder };

OrderProductCorrectionBatch batch = new OrderProductCorrectionBatch();
batch.execute(null, ordersToFix);

System.debug('Order 00000137 보정 완료');
```

### 배치 실행 (전체 Order 보정)
```apex
// 모든 Order Product 누락 건 보정
OrderProductCorrectionBatch batch = new OrderProductCorrectionBatch();
Database.executeBatch(batch, 50);
```

## 📊 예상 결과

### Order 00000137 보정 후
```
Order Products:
- 카셰어링 플래티넘(PLATINUM) × 100개
- 단가: ₩127,200
- 총액: ₩10,176,000

PaymentStatus (년별):
- 1차: ₩10,176,000 (2025.7.17)

또는 PaymentStatus (분기별):
- 1차: ₩2,544,000 (2025.7.17)
- 2차: ₩2,544,000 (2025.10.17)
- 3차: ₩2,544,000 (2026.1.17)
- 4차: ₩2,544,000 (2026.4.17)
```

## 🔍 검증 방법

1. **Order Product 생성 확인**
2. **Order Amount 정정 확인**
3. **PaymentStatus 금액 정정 확인**
4. **납부 타임라인 정상 동작 확인**

이 설계안을 통해 Opportunity Product → Order Product 자동 전환이 완성됩니다! 🎯

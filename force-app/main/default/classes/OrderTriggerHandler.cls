public with sharing class OrderTriggerHandler extends TriggerHandler {

    // after insert 로직
    protected override void afterInsert(List<SObject> news, Map<Id, SObject> newMap) {
        Set<Id> orderIdsToProcess = new Set<Id>();
        List<Order> newOrders = (List<Order>)news;

        for (Order ord : newOrders) {
            // 납부 방식이 지정된 경우에만 처리 대상에 추가
            if (String.isNotBlank(ord.Payment_Method__c)) {
                orderIdsToProcess.add(ord.Id);
            }
        }
        
        // 서비스 호출
        if (!orderIdsToProcess.isEmpty()) {
            PaymentScheduleService.createSchedules(orderIdsToProcess);
        }
    }

    // after update 로직
    protected override void afterUpdate(List<SObject> news, List<SObject> olds, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        Set<Id> orderIdsToProcess = new Set<Id>();
        Map<Id, Order> oldOrderMap = (Map<Id, Order>)oldMap;

        for (Order newOrd : (List<Order>)news) {
            Order oldOrd = oldOrderMap.get(newOrd.Id);

            // 납부 방식 또는 총액이 변경된 경우 처리 대상에 추가
            if (newOrd.Payment_Method__c != oldOrd.Payment_Method__c || newOrd.TotalAmount != oldOrd.TotalAmount) {
                orderIdsToProcess.add(newOrd.Id);
            }
        }

        // 서비스 호출
        if (!orderIdsToProcess.isEmpty()) {
            PaymentScheduleService.createSchedules(orderIdsToProcess);
        }
    }
}
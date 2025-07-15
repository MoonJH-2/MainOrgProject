/**
 * @description       : 
 * @author            : JH Moon
 * @last modified on  : 07-12-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class OrderTriggerHandler extends TriggerHandler {
    /** 
     * 현재 핸들러 이름 반환 
     * isFirstRun() 및 바이패스 기능(bypass, clearBypass)이 각 핸들러를 고유하게 식별하기 위해 필요
    **/
    protected override String getHandlerName() {
        return 'OrderTriggerHandler';
    }

    protected override void beforeInsert(List<SObject> news) {
        System.debug('Order Trigger Before Insert Start');
        
        List<Order> newOrders = (List<Order>) news;

        Set<Id> accountId = new Set<Id>();
        for (Order ord : newOrders) {
            if(ord.AccountId != null){
                accountId.add(ord.AccountId);
            }
        }
        
        if(!accountId.isEmpty()){
            // Map<Id, Account> convertAccMap = new Map<Id,Account>();
            Id activeRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ActiveCustomer').getRecordTypeId();

            Map<Id, Account> accMap = new Map<Id, Account>();
            List<Account> accList = [
                SELECT  Id
                        , BusinessNumberVerified__c
                        , RecordTypeId
                FROM Account
                WHERE Id IN :accountId
            ];

            for(Account acc : accList) {
                accMap.put(acc.Id, acc);
            }

            List<Account> updateAccRecordType = new List<Account>();
            for(Order ord : newOrders) {
                if(ord.AccountId != null){
                    Account relatedAcc = accMap.get(ord.AccountId);
                    if(relatedAcc != null) {
                        if(relatedAcc != null && !relatedAcc.BusinessNumberVerified__c) {
                            ord.addError('사업자 번호가 검증되지 않았습니다. 주문을 생성할 수 없습니다.');
                        } else if (relatedAcc.RecordTypeId != activeRecordType){
                            relatedAcc.RecordTypeId = activeRecordType;
                            updateAccRecordType.add(relatedAcc);
                        }
                    }
                }
            }

            if(!updateAccRecordType.isEmpty()){
                update updateAccRecordType;
            }
        }

        System.debug('Order Trigger Before Insert Finish');
    }
    
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
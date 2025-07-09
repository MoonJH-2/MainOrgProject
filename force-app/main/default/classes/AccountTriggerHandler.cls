/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-07-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class AccountTriggerHandler extends TriggerHandler {
    /** 
     * 현재 핸들러 이름 반환 
     * isFirstRun() 및 바이패스 기능(bypass, clearBypass)이 각 핸들러를 고유하게 식별하기 위해 필요
    **/
    protected override String getHandlerName() {
        return 'AccountTriggerHandler';
    }

    protected override void beforeInsert(List<SObject> news) {
        System.debug('Account Trigger Before Insert Start');

        for (Account acc : (List<Account>) news) {
            
        }

        System.debug('Account Trigger Before Insert Finish');
    }

    protected override void afterInsert(List<SObject> news, Map<Id, SObject> newMap) {
        System.debug('Account Trigger After Insert Start');

        for (Account acc : (List<Account>) news) {
            
        }

        System.debug('Account Trigger After Insert Finish');
    }

    protected override void beforeUpdate(List<SObject> news, List<SObject> olds, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        System.debug('Account Trigger Before Update Start');
        
        // 🐥🩵 왜 Map에 담는지?
        Map<Account, String> businessNumberByAccMap = new Map<Account, String>();

        for (Account acc : (List<Account>) news) {
            Account oldAcc = (Account) oldMap.get(acc.Id);

            if(String.isNotBlank(acc.BusinessNumber__c)){
                String oldBusinessNumber = oldAcc.BusinessNumber__c != null ? formatBusinessNumber(oldAcc.BusinessNumber__c) : '';
                String newBusinessNumber = formatBusinessNumber(acc.BusinessNumber__c);

                if(oldBusinessNumber != newBusinessNumber){
                    acc.BusinessNumberDuplication__c = newBusinessNumber;
                    
                    if(acc.BusinessNumberVerified__c) acc.BusinessNumberVerified__c = false;
                    businessNumberByAccMap.put(acc, acc.BusinessNumberDuplication__c);                
                }
            }
    
        }
        if(!businessNumberByAccMap.isEmpty()){
            businessNumberDuplCheck(businessNumberByAccMap);
        }
        
        System.debug('Account Trigger Before Update Finish');
    }

    protected override void afterUpdate(List<SObject> news, List<SObject> olds, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        System.debug('Account Trigger After Update Start');

        for (Account acc : (List<Account>) news) {
            Account oldAcc = (Account)oldMap.get(acc.Id);
            
        }

        System.debug('Account Trigger After Update Finish');
    }

    private static String formatBusinessNumber(String businessNumber){
        String numericString = '';
        Pattern p = Pattern.compile('\\d+');
        Matcher m = p.matcher(businessNumber);

        while (m.find()) {
            numericString += m.group();
        }

        return numericString;
    }

    private static void businessNumberDuplCheck(Map<Account, String> businessNumberByAccMap){
        List<Account> accList = [
            SELECT  Id
                    , BusinessNumberDuplication__c
            FROM Account
            // 🐥🩵 businessNumberByAccMap.values() -> values()? 
            WHERE BusinessNumberDuplication__c IN :businessNumberByAccMap.values()
        ];

        if(!accList.isEmpty()){
            List<String> businessNumbers = new List<String>();
            
            for(Account acc : accList){
                businessNumbers.add(acc.BusinessNumberDuplication__c);
            }

            for(Account triggerAcc : businessNumberByAccMap.keySet()){
                if(businessNumbers.contains(triggerAcc.BusinessNumberDuplication__c)){
                    triggerAcc.BusinessNumber__c.addError('이미 존재하는 사업자등록번호 입니다.');
                }
            }
        }
        return;
    }
}
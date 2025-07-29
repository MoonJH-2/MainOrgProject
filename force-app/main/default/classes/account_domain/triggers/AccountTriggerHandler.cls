/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-14-2025
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

        List<Account> accList = new List<Account>();

        for (Account acc : (List<Account>) news) {
            Account oldAcc = (Account)oldMap.get(acc.Id);

            if(acc.Key_Account__c && !oldAcc.Key_Account__c){
                accList.add(acc);
            }            
        }

        if(!accList.isEmpty()){
            keyAccoutNoti(accList);
            sendKeyAccountEmail(accList);
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

    private static void keyAccoutNoti(List<Account> accList){
        CustomNotificationType notificationType = [
            SELECT  Id
                    , DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'Key_Account_Notification'
        ];

        User user = [
            SELECT  Id
                    , ManagerId
            FROM User
            WHERE Id =: UserInfo.getUserId()
            LIMIT 1
        ];

        Set<String> recipient = new Set<String>();
        recipient.add(user.ManagerId);
        // recipient.add(user.Id);


        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        for(Account acc : accList){
            notification.setTitle('주요 고객');
            notification.setBody('주요 고객입니다.');
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(acc.Id);
            notification.send(recipient);
        }

    }

    private static void sendKeyAccountEmail (List<Account> accList) {
        List<EmailTemplate> emailTemplates = [
            SELECT  Id
                    , DeveloperName
                    , Subject
                    , HtmlValue
                    , Body
            FROM EmailTemplate
            WHERE DeveloperName = 'New_Key_Account_Email_Alert'
            LIMIT 1
        ];

        EmailTemplate emailTemplate = emailTemplates[0];

        User user = [
            SELECT  Id
                    , Email
                    , Name
                    , ManagerId
                    , Manager.Email
            FROM User
            WHERE Id =: UserInfo.getUserId()
            LIMIT 1
        ];

        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        String registrationDate = Date.today().format();
        
        for(Account acc : accList){
            String accountLink = URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id;
            
            String[] templateParams = new String[] {
                acc.Name,
                user.Name,
                registrationDate,
                accountLink
            };
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            // email.setToAddresses(new String[]{user.Email});
            email.setToAddresses(new String[]{user.Manager.Email});
            email.setTemplateId(emailTemplate.Id);
            email.setTargetObjectId(user.ManagerId);
            // email.setTargetObjectId(user.Id);
            email.setWhatId(acc.Id);
            email.setSaveAsActivity(false);

            String htmlBody = emailTemplate.HtmlValue;
            String body = emailTemplate.Body;
            for(Integer i = 0; i < templateParams.size(); i++){
                htmlBody = htmlBody.replace('{' + i + '}', templateParams[i]);
                body = body.replace('{' + i + '}', templateParams[i]);
            }
            email.setSubject(emailTemplate.Subject);
            email.setHtmlBody(htmlBody);
            email.setPlainTextBody(body);

            emails.add(email);
        }

        if(!emails.isEmpty()) Messaging.sendEmail(emails);
    }
}
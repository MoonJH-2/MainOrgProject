/**
 * @description       : 연체 체크 배치 클래스
 * @author            : JH Moon
 * @last modified on  : 07-16-2025
 * @last modified by  : JH Moon
**/
public class PaymentOverdueCheckBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        Date today = Date.today();
        
        // 연체된 PaymentStatus 조회
        return Database.getQueryLocator([
            SELECT Id, Order__c, Order__r.OrderNumber, Order__r.Account.Name,
                   Amount__c, DueDate__c, Installment_Number__c, Status__c
            FROM PaymentStatus__c 
            WHERE DueDate__c < :today 
            AND Status__c = '미납'
            ORDER BY DueDate__c ASC
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<PaymentStatus__c> scope) {
        try {
            List<Id> paymentStatusIds = new List<Id>();
            
            for (PaymentStatus__c ps : scope) {
                paymentStatusIds.add(ps.Id);
            }
            
            if (!paymentStatusIds.isEmpty()) {
                PaymentStatusTimelineController.checkOverdueAndCreateTasks(paymentStatusIds);
            }
            
        } catch (Exception e) {
            System.debug('PaymentOverdueCheckBatch 실행 중 오류: ' + e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext context) {
        // 배치 완료 로그
        System.debug('PaymentOverdueCheckBatch 완료: ' + System.now());
        
        // 필요시 관리자에게 이메일 발송
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob 
            WHERE Id = :context.getJobId()
        ];
        
        if (job.NumberOfErrors > 0) {
            System.debug('배치 처리 중 ' + job.NumberOfErrors + '개의 오류가 발생했습니다.');
        }
    }
}

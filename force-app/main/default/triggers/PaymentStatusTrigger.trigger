/**
 * @description PaymentStatus 트리거
 * @author JH Moon
 * @date 2025-07-15
 */
trigger PaymentStatusTrigger on PaymentStatus__c (after insert, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            // 새로운 PaymentStatus 생성 시 알림 스케줄링
            PaymentNotificationScheduler.scheduleNotifications(Trigger.new);
            
            // 새로 생성된 PaymentStatus 중 이미 연체된 것들 즉시 체크
            PaymentOverdueService.checkNewPaymentStatus(Trigger.new);
            
            // Sales 앱 알림: 새로 생성되었지만 이미 연체인 경우
            PaymentStatusTriggerHandler.afterInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            // 완납 처리된 PaymentStatus의 알림 취소
            List<PaymentStatus__c> completedPayments = new List<PaymentStatus__c>();
            List<Id> statusChangedIds = new List<Id>();
            List<Id> dueDateChangedIds = new List<Id>();
            
            for (PaymentStatus__c newPS : Trigger.new) {
                PaymentStatus__c oldPS = Trigger.oldMap.get(newPS.Id);
                
                // 상태가 미납 → 완납으로 변경된 경우
                if (oldPS.Status__c != '완납' && newPS.Status__c == '완납') {
                    completedPayments.add(newPS);
                }
                
                // 상태가 변경된 경우 Task 생성 체크
                if (oldPS.Status__c != newPS.Status__c) {
                    statusChangedIds.add(newPS.Id);
                }
                
                // DueDate가 변경된 경우 (즉시 연체 체크를 위해)
                if (oldPS.DueDate__c != newPS.DueDate__c) {
                    dueDateChangedIds.add(newPS.Id);
                }
            }
            
            if (!completedPayments.isEmpty()) {
                PaymentNotificationScheduler.cancelNotifications(completedPayments);
            }
            
            // 상태 변경 시 Task 생성
            if (!statusChangedIds.isEmpty()) {
                PaymentStatusTimelineController.checkOverdueAndCreateTasks(statusChangedIds);
            }
            
            // DueDate 변경 시 즉시 연체 체크
            if (!dueDateChangedIds.isEmpty()) {
                PaymentStatusTimelineController.checkOverdueAndCreateTasks(dueDateChangedIds);
            }
            
            // Sales 앱 알림: 연체 상태로 변경된 경우
            PaymentStatusTriggerHandler.afterUpdate(Trigger.new, Trigger.old);
        }
    }
}

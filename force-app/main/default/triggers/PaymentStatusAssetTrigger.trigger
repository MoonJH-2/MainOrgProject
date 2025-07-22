/**
 * @description PaymentStatus 트리거 - 완납 시 Asset 자동 생성
 * @author Copilot
 * @date 2024
 */
trigger PaymentStatusAssetTrigger on PaymentStatus__c (after insert, after update) {
    
    if (Trigger.isAfter) {
        
        if (Trigger.isInsert) {
            // PaymentStatus 생성 후 처리
            PaymentStatusAssetTriggerHandler.handleAfterInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            // PaymentStatus 업데이트 후 처리
            PaymentStatusAssetTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}

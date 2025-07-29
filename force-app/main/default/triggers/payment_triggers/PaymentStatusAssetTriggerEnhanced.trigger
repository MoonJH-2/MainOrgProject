/**
 * @description Enhanced PaymentStatus Trigger with VIBA Integration
 * @author VIBA AI Assistant  
 * @date 2025-01-27
 * @version 2.0 - VIBA AI 통합 버전
 */
trigger PaymentStatusAssetTriggerEnhanced on PaymentStatus__c (before insert, before update, after insert, after update) {
    
    // VIBA 기능 활성화 확인
    Boolean vibaEnabled = VIBAFeatureManager.isVIBAEnabled();
    
    if (Trigger.isBefore) {
        
        if (Trigger.isUpdate && vibaEnabled) {
            // VIBA 기반 전처리 (AI 점수 계산, 권장 액션 설정)
            PaymentStatusAssetTriggerHandlerEnhanced.handleBeforeUpdateWithVIBA(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        
        if (Trigger.isInsert) {
            if (vibaEnabled) {
                // VIBA 통합 처리
                PaymentStatusAssetTriggerHandlerEnhanced.handleAfterInsertWithVIBA(Trigger.new);
            } else {
                // 기본 처리 (기존 로직 유지)
                PaymentStatusAssetTriggerHandler.handleAfterInsert(Trigger.new);
            }
        }
        
        if (Trigger.isUpdate) {
            if (vibaEnabled) {
                // VIBA 통합 처리
                PaymentStatusAssetTriggerHandlerEnhanced.handleAfterUpdateWithVIBA(Trigger.new, Trigger.oldMap);
            } else {
                // 기본 처리 (기존 로직 유지)
                PaymentStatusAssetTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
            }
        }
    }
}

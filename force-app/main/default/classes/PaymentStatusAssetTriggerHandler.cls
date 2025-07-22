/**
 * @description PaymentStatus 완납 시 Asset 생성 트리거 핸들러
 * @author Copilot
 * @date 2024
 */
public class PaymentStatusAssetTriggerHandler {
    
    /**
     * @description PaymentStatus 업데이트 후 처리
     * @param updatedPaymentStatuses 업데이트된 PaymentStatus 목록
     * @param oldPaymentStatusMap 이전 PaymentStatus 맵
     */
    public static void handleAfterUpdate(List<PaymentStatus__c> updatedPaymentStatuses, Map<Id, PaymentStatus__c> oldPaymentStatusMap) {
        // 완납으로 변경된 PaymentStatus의 Order ID 수집
        Set<Id> orderIdsToCheck = new Set<Id>();
        
        for (PaymentStatus__c paymentStatus : updatedPaymentStatuses) {
            PaymentStatus__c oldPaymentStatus = oldPaymentStatusMap.get(paymentStatus.Id);
            
            // 상태가 완납으로 변경된 경우
            if (paymentStatus.Status__c == '완납' && oldPaymentStatus.Status__c != '완납') {
                orderIdsToCheck.add(paymentStatus.Order__c);
                System.debug('PaymentStatusAssetTriggerHandler: 완납 상태 변경 감지. PaymentStatusId: ' + paymentStatus.Id + ', OrderId: ' + paymentStatus.Order__c);
            }
        }
        
        if (!orderIdsToCheck.isEmpty()) {
            processOrdersForAssetCreation(orderIdsToCheck);
        }
    }
    
    /**
     * @description PaymentStatus 삽입 후 처리
     * @param newPaymentStatuses 새로 생성된 PaymentStatus 목록
     */
    public static void handleAfterInsert(List<PaymentStatus__c> newPaymentStatuses) {
        // 완납 상태로 생성된 PaymentStatus의 Order ID 수집
        Set<Id> orderIdsToCheck = new Set<Id>();
        
        for (PaymentStatus__c paymentStatus : newPaymentStatuses) {
            if (paymentStatus.Status__c == '완납') {
                orderIdsToCheck.add(paymentStatus.Order__c);
                System.debug('PaymentStatusAssetTriggerHandler: 완납 상태로 생성 감지. PaymentStatusId: ' + paymentStatus.Id + ', OrderId: ' + paymentStatus.Order__c);
            }
        }
        
        if (!orderIdsToCheck.isEmpty()) {
            processOrdersForAssetCreation(orderIdsToCheck);
        }
    }
    
    /**
     * @description Order들의 완납 상태를 확인하고 Asset 생성
     * @param orderIds 확인할 Order ID 집합
     */
    private static void processOrdersForAssetCreation(Set<Id> orderIds) {
        List<Id> orderIdsList = new List<Id>(orderIds);
        
        try {
            // 비동기 처리로 Asset 생성 (트리거 제한 방지)
            if (!System.isBatch() && !System.isFuture()) {
                createAssetsAsync(orderIdsList);
            } else {
                // 이미 비동기 컨텍스트인 경우 동기 처리
                createAssetsSync(orderIdsList);
            }
            
        } catch (Exception e) {
            System.debug('PaymentStatusAssetTriggerHandler.processOrdersForAssetCreation Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description 비동기로 Asset 생성
     * @param orderIds Order ID 목록
     */
    @future
    public static void createAssetsAsync(List<Id> orderIds) {
        createAssetsSync(orderIds);
    }
    
    /**
     * @description 동기적으로 Asset 생성
     * @param orderIds Order ID 목록
     */
    public static void createAssetsSync(List<Id> orderIds) {
        for (Id orderId : orderIds) {
            try {
                // 완납 상태 확인
                if (OrderAssetCreationService.isOrderFullyPaid(orderId)) {
                    System.debug('PaymentStatusAssetTriggerHandler: Order 완납 확인됨. Account 기반 Asset 생성 시작. OrderId: ' + orderId);
                    
                    // Account 분석 기반 Asset 생성 사용
                    Asset newAsset = AccountBasedAssetService.createAssetWithAccountAnalysis(orderId);
                    
                    if (newAsset != null) {
                        System.debug('PaymentStatusAssetTriggerHandler: Account 기반 Asset 생성 성공. AssetId: ' + newAsset.Id + ', OrderId: ' + orderId);
                    }
                } else {
                    System.debug('PaymentStatusAssetTriggerHandler: Order가 아직 완납되지 않음. OrderId: ' + orderId);
                }
                
            } catch (Exception e) {
                System.debug('PaymentStatusAssetTriggerHandler.createAssetsSync Error for OrderId ' + orderId + ': ' + e.getMessage());
                
                // 오류 발생 시 관리자에게 알림 Task 생성
                createErrorNotificationTask(orderId, e.getMessage());
            }
        }
    }
    
    /**
     * @description Asset 생성 오류 시 관리자 알림 Task 생성
     * @param orderId 오류 발생한 Order ID
     * @param errorMessage 오류 메시지
     */
    private static void createErrorNotificationTask(Id orderId, String errorMessage) {
        try {
            Order orderInfo = [
                SELECT Id, OrderNumber, Account.Name, Owner.Name, OwnerId
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            Task errorTask = new Task();
            errorTask.Subject = '[Asset 생성 오류] ' + orderInfo.Account.Name + ' - Order ' + orderInfo.OrderNumber;
            errorTask.Description = 'PaymentStatus 완납 처리 중 Asset 자동 생성에서 오류가 발생했습니다.\n\n';
            errorTask.Description += '고객: ' + orderInfo.Account.Name + '\n';
            errorTask.Description += 'Order: ' + orderInfo.OrderNumber + '\n';
            errorTask.Description += '오류 메시지: ' + errorMessage + '\n\n';
            errorTask.Description += '수동으로 Asset 생성을 확인해주세요.';
            
            errorTask.Priority = 'High';
            errorTask.Status = 'Not Started';
            errorTask.ActivityDate = Date.today().addDays(1);
            errorTask.OwnerId = orderInfo.OwnerId;
            errorTask.WhatId = orderId;
            
            insert errorTask;
            
        } catch (Exception e) {
            System.debug('PaymentStatusAssetTriggerHandler.createErrorNotificationTask Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description 대량 PaymentStatus 업데이트 시 성능 최적화된 처리
     * @param paymentStatuses PaymentStatus 목록
     * @param oldPaymentStatusMap 이전 값 맵
     */
    public static void handleBulkUpdate(List<PaymentStatus__c> paymentStatuses, Map<Id, PaymentStatus__c> oldPaymentStatusMap) {
        // 대량 처리 시 중복 Order 제거
        Set<Id> uniqueOrderIds = new Set<Id>();
        
        for (PaymentStatus__c paymentStatus : paymentStatuses) {
            PaymentStatus__c oldPaymentStatus = oldPaymentStatusMap?.get(paymentStatus.Id);
            
            if (paymentStatus.Status__c == '완납' && 
                (oldPaymentStatus == null || oldPaymentStatus.Status__c != '완납')) {
                uniqueOrderIds.add(paymentStatus.Order__c);
            }
        }
        
        if (!uniqueOrderIds.isEmpty()) {
            System.debug('PaymentStatusAssetTriggerHandler: 대량 처리 - ' + uniqueOrderIds.size() + '개 Order Asset 생성 확인');
            processOrdersForAssetCreation(uniqueOrderIds);
        }
    }
}

/**
 * @description PaymentStatus__c 객체의 Trigger Handler
 * 연체 상태 변경 시 Sales 앱 알림 발송
 * @author JH Moon
 * @last modified on 07-21-2025
 * @last modified by JH Moon
 */
public with sharing class PaymentStatusTriggerHandler {
    
    /**
     * After Update 처리
     * 연체 상태로 변경된 PaymentStatus에 대해 알림 발송
     */
    public static void afterUpdate(List<PaymentStatus__c> newPayments, List<PaymentStatus__c> oldPayments) {
        try {
            System.debug('🚨 PaymentStatus afterUpdate 시작: ' + newPayments.size() + '개');
            
            // 연체로 변경된 PaymentStatus 필터링
            List<PaymentStatus__c> overduePayments = OrderNotificationService.getOverduePayments(newPayments, oldPayments);
            
            if (!overduePayments.isEmpty()) {
                System.debug('📋 연체 상태로 변경된 PaymentStatus: ' + overduePayments.size() + '개');
                
                // PaymentStatus 상세 정보 조회 (알림을 위한 추가 정보)
                Set<Id> paymentIds = new Set<Id>();
                for (PaymentStatus__c payment : overduePayments) {
                    paymentIds.add(payment.Id);
                }
                
                List<PaymentStatus__c> overduePaymentsWithDetails = [
                    SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber,
                           InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
                           Order__r.Owner.Name, Order__r.Owner.Email
                    FROM PaymentStatus__c 
                    WHERE Id IN :paymentIds
                ];
                
                // Sales 앱 연체 알림 발송
                OrderNotificationService.notifyOverduePayments(overduePaymentsWithDetails);
                
                System.debug('✅ PaymentStatus 연체 알림 처리 완료');
            } else {
                System.debug('ℹ️ 연체로 변경된 PaymentStatus가 없습니다.');
            }
            
        } catch (Exception e) {
            System.debug('❌ PaymentStatus afterUpdate 오류: ' + e.getMessage());
            System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
        }
    }
    
    /**
     * After Insert 처리
     * 새로 생성된 PaymentStatus가 이미 연체인 경우 알림 발송
     */
    public static void afterInsert(List<PaymentStatus__c> newPayments) {
        try {
            System.debug('🆕 PaymentStatus afterInsert 시작: ' + newPayments.size() + '개');
            
            // 새로 생성되었지만 이미 연체인 PaymentStatus 필터링
            List<PaymentStatus__c> overduePayments = new List<PaymentStatus__c>();
            
            for (PaymentStatus__c payment : newPayments) {
                if (payment.Status__c == '연체' && payment.DueDate__c < Date.today()) {
                    overduePayments.add(payment);
                }
            }
            
            if (!overduePayments.isEmpty()) {
                System.debug('📋 새로 생성된 연체 PaymentStatus: ' + overduePayments.size() + '개');
                
                // PaymentStatus 상세 정보 조회
                Set<Id> paymentIds = new Set<Id>();
                for (PaymentStatus__c payment : overduePayments) {
                    paymentIds.add(payment.Id);
                }
                
                List<PaymentStatus__c> overduePaymentsWithDetails = [
                    SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber,
                           InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
                           Order__r.Owner.Name, Order__r.Owner.Email
                    FROM PaymentStatus__c 
                    WHERE Id IN :paymentIds
                ];
                
                // Sales 앱 연체 알림 발송
                OrderNotificationService.notifyOverduePayments(overduePaymentsWithDetails);
                
                System.debug('✅ PaymentStatus 신규 연체 알림 처리 완료');
            } else {
                System.debug('ℹ️ 새로 생성된 연체 PaymentStatus가 없습니다.');
            }
            
        } catch (Exception e) {
            System.debug('❌ PaymentStatus afterInsert 오류: ' + e.getMessage());
            System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
        }
    }
    
    /**
     * 연체 상태 체크 및 대량 알림 처리 (Batch에서 호출 가능)
     */
    public static void processOverduePaymentsBatch(List<PaymentStatus__c> paymentsToCheck) {
        try {
            System.debug('🔄 PaymentStatus 배치 연체 처리 시작: ' + paymentsToCheck.size() + '개');
            
            List<PaymentStatus__c> currentOverduePayments = new List<PaymentStatus__c>();
            
            for (PaymentStatus__c payment : paymentsToCheck) {
                // 연체 조건 확인: 상태가 '연체'이고 마감일이 지났음
                if (payment.Status__c == '연체' && payment.DueDate__c < Date.today()) {
                    currentOverduePayments.add(payment);
                }
            }
            
            if (!currentOverduePayments.isEmpty()) {
                // Sales 앱 연체 알림 발송
                OrderNotificationService.notifyOverduePayments(currentOverduePayments);
                
                System.debug('✅ 배치 연체 알림 처리 완료: ' + currentOverduePayments.size() + '개');
            } else {
                System.debug('ℹ️ 배치에서 처리할 연체 PaymentStatus가 없습니다.');
            }
            
        } catch (Exception e) {
            System.debug('❌ PaymentStatus 배치 처리 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 연체 상태 자동 업데이트 (스케줄러에서 호출 가능)
     */
    public static void updateOverdueStatus() {
        try {
            System.debug('🕐 PaymentStatus 연체 상태 자동 업데이트 시작');
            
            // 마감일이 지났지만 아직 연체 상태가 아닌 PaymentStatus 조회
            List<PaymentStatus__c> paymentsToUpdate = [
                SELECT Id, Status__c, DueDate__c, Order__c,
                       Order__r.Account.Name, Order__r.OrderNumber,
                       InstallmentNumber__c, Amount__c
                FROM PaymentStatus__c 
                WHERE DueDate__c < TODAY
                AND Status__c != '연체'
                AND Status__c != '완납'
                LIMIT 200
            ];
            
            if (!paymentsToUpdate.isEmpty()) {
                // 상태를 연체로 업데이트
                for (PaymentStatus__c payment : paymentsToUpdate) {
                    payment.Status__c = '연체';
                }
                
                update paymentsToUpdate;
                
                System.debug('✅ 연체 상태 자동 업데이트 완료: ' + paymentsToUpdate.size() + '개');
                
                // 알림 발송
                OrderNotificationService.notifyOverduePayments(paymentsToUpdate);
                
            } else {
                System.debug('ℹ️ 업데이트할 연체 PaymentStatus가 없습니다.');
            }
            
        } catch (Exception e) {
            System.debug('❌ 연체 상태 자동 업데이트 오류: ' + e.getMessage());
        }
    }
}

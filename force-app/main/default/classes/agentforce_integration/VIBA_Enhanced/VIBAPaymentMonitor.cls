/**
 * @description VIBA Payment Monitor - 결제 모니터링
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */
public with sharing class VIBAPaymentMonitor {
    
    public static void handleOverdueRisk(List<PaymentStatus__c> newPayments, Map<Id, PaymentStatus__c> oldMap) {
        for (PaymentStatus__c payment : newPayments) {
            PaymentStatus__c oldPayment = oldMap?.get(payment.Id);
            
            // 상태 변경 감지
            if (oldPayment != null && payment.Status__c != oldPayment.Status__c) {
                if (payment.Status__c == '연체') {
                    System.debug('🚨 연체 위험 감지: ' + payment.Id);
                    VIBANotificationService.sendOverdueAlert(payment);
                } else if (payment.Status__c == '완납') {
                    System.debug('🎉 완납 완료: ' + payment.Id);
                    VIBANotificationService.sendPaymentCompletionAlert(payment.Id);
                }
            }
        }
    }
    
    public static void analyzeAndRecommend(List<PaymentStatus__c> paymentStatuses) {
        for (PaymentStatus__c payment : paymentStatuses) {
            // AI 위험도 분석
            Decimal riskScore = VIBARiskAnalyzer.calculatePaymentRisk(payment);
            payment.AI_Risk_Score__c = riskScore;
            
            // 권장 액션 생성
            if (riskScore > 70) {
                payment.AI_Recommended_Action__c = VIBAActionGenerator.generateOverdueAction(payment);
            } else if (payment.Status__c == '완납') {
                payment.AI_Recommended_Action__c = VIBAActionGenerator.generateCompletionAction(payment);
            }
        }
    }
}

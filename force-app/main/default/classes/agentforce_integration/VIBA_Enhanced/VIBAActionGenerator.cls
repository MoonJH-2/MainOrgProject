/**
 * @description VIBA Action Generator - 권장 액션 생성
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */
public with sharing class VIBAActionGenerator {
    
    public static String generateOverdueAction(PaymentStatus__c paymentStatus) {
        return '🚨 연체 고객 즉시 연락: ' + (paymentStatus.DueDate__c != null ? paymentStatus.DueDate__c.format() : '날짜 미확인') + ' 만료';
    }
    
    public static String generateCompletionAction(PaymentStatus__c paymentStatus) {
        return '🎉 완납 고객 감사 인사 및 다음 서비스 안내';
    }
    
    public static List<String> generateSmartRecommendations(Decimal riskScore) {
        List<String> recommendations = new List<String>();
        
        if (riskScore > 70) {
            recommendations.add('즉시 고객 연락 필요');
            recommendations.add('결제 계획 재조정 검토');
        } else if (riskScore > 40) {
            recommendations.add('정기 상태 확인');
            recommendations.add('예방적 고객 관리');
        } else {
            recommendations.add('우수 고객 유지 관리');
            recommendations.add('추가 서비스 제안 기회');
        }
        
        return recommendations;
    }
}

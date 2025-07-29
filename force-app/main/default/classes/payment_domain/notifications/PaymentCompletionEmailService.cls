/**
 * Payment 완납 이메일 서비스
 * @author JH Moon
 * @created 2025-07-22
 */
public with sharing class PaymentCompletionEmailService {
    
    /**
     * 완납 이메일 발송
     */
    public static Boolean sendCompletionEmail(String orderId) {
        try {
            System.debug('📧 완납 이메일 발송 처리: ' + orderId);
            // 향후 구현 예정
            return true;
        } catch (Exception e) {
            System.debug('❌ 완납 이메일 오류: ' + e.getMessage());
            return false;
        }
    }
}
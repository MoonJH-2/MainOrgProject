/**
 * @description 간단한 Agentforce 이메일 액션 서비스
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceSimpleEmailActions {
    
    /**
     * 범용 이메일 초안 생성
     */
    @InvocableMethod(label='Generate Email Draft' description='상황에 따른 이메일 초안을 생성합니다')
    public static List<EmailResult> generateEmailDraft(List<EmailRequest> requests) {
        List<EmailResult> results = new List<EmailResult>();
        
        for(EmailRequest request : requests) {
            EmailResult result = new EmailResult();
            
            try {
                switch on request.emailType {
                    when 'order' {
                        result = generateOrderEmail(request);
                    }
                    when 'payment' {
                        result = generatePaymentEmail(request);
                    }
                    when 'asset_renewal' {
                        result = generateAssetEmail(request);
                    }
                    when else {
                        result = generateGeneralEmail(request);
                    }
                }
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Order 이메일 생성
    private static EmailResult generateOrderEmail(EmailRequest request) {
        EmailResult result = new EmailResult();
        
        try {
            Order orderRecord = [
                SELECT Id, OrderNumber, Status, AccountId, Account.Name, 
                       TotalAmount, EffectiveDate
                FROM Order 
                WHERE Id = :request.recordId 
                LIMIT 1
            ];
            
            result.emailSubject = '[SOCAR] 주문 관련 안내 - ' + orderRecord.OrderNumber;
            result.emailBody = '안녕하세요 ' + orderRecord.Account.Name + ' 고객님,\n\n' +
                              '주문 ' + orderRecord.OrderNumber + '에 대한 안내입니다.\n\n' +
                              '주문 금액: ' + String.valueOf(orderRecord.TotalAmount) + '\n' +
                              '시작일: ' + orderRecord.EffectiveDate?.format() + '\n\n' +
                              '문의사항이 있으시면 연락 주세요.\n\n' +
                              '감사합니다.\nSOCAR B2B 영업팀';
            
            result.success = true;
            result.recipientEmail = 'customer@example.com'; // 기본값
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '주문 이메일 생성 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Payment 이메일 생성
    private static EmailResult generatePaymentEmail(EmailRequest request) {
        EmailResult result = new EmailResult();
        
        try {
            // 간단한 기본 이메일
            result.emailSubject = '[SOCAR] 결제 관련 안내';
            result.emailBody = '안녕하세요,\n\n' +
                              '결제 관련 안내입니다.\n\n' +
                              '문의사항이 있으시면 연락 주세요.\n\n' +
                              '감사합니다.\nSOCAR B2B 영업팀';
            
            result.success = true;
            result.recipientEmail = 'customer@example.com';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '결제 이메일 생성 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Asset 이메일 생성
    private static EmailResult generateAssetEmail(EmailRequest request) {
        EmailResult result = new EmailResult();
        
        try {
            Asset assetRecord = [
                SELECT Id, Name, AccountId, Account.Name
                FROM Asset 
                WHERE Id = :request.recordId 
                LIMIT 1
            ];
            
            result.emailSubject = '[SOCAR] 서비스 관련 안내 - ' + assetRecord.Name;
            result.emailBody = '안녕하세요 ' + assetRecord.Account.Name + ' 고객님,\n\n' +
                              '서비스 ' + assetRecord.Name + ' 관련 안내입니다.\n\n' +
                              '문의사항이 있으시면 연락 주세요.\n\n' +
                              '감사합니다.\nSOCAR B2B 영업팀';
            
            result.success = true;
            result.recipientEmail = 'customer@example.com';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Asset 이메일 생성 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // 일반 이메일 생성
    private static EmailResult generateGeneralEmail(EmailRequest request) {
        EmailResult result = new EmailResult();
        
        result.emailSubject = '[SOCAR] 고객 안내';
        result.emailBody = '안녕하세요,\n\n' +
                          'SOCAR B2B 영업팀입니다.\n\n' +
                          (String.isNotBlank(request.additionalContext) ? 
                           request.additionalContext + '\n\n' : '') +
                          '문의사항이 있으시면 언제든지 연락 주세요.\n\n' +
                          '감사합니다.\nSOCAR B2B 영업팀';
        
        result.success = true;
        result.recipientEmail = 'customer@example.com';
        
        return result;
    }
    
    // Wrapper Classes
    public class EmailRequest {
        @InvocableVariable(label='Record ID' required=true)
        public String recordId;
        
        @InvocableVariable(label='Email Type' required=true)
        public String emailType; // order, payment, asset_renewal, general
        
        @InvocableVariable(label='Sub Type')
        public String subType;
        
        @InvocableVariable(label='Additional Context')
        public String additionalContext;
    }
    
    public class EmailResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String emailSubject;
        
        @InvocableVariable
        public String emailBody;
        
        @InvocableVariable
        public String recipientEmail;
        
        @InvocableVariable
        public String errorMessage;
        
        public EmailResult() {
            this.success = false;
        }
    }
    
    // 기존 호환성을 위한 클래스들
    public class OrderEmailRequest {
        @InvocableVariable
        public String orderId;
        @InvocableVariable
        public String emailType;
    }
    
    public class PaymentEmailRequest {
        @InvocableVariable
        public String paymentId;
        @InvocableVariable
        public String notificationType;
    }
    
    public class AssetEmailRequest {
        @InvocableVariable
        public String assetId;
        @InvocableVariable
        public String renewalType;
    }
    
    public class EmailDraftResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String emailSubject;
        @InvocableVariable
        public String emailBody;
        @InvocableVariable
        public String recipientEmail;
        @InvocableVariable
        public String errorMessage;
        
        public EmailDraftResult() {
            this.success = false;
        }
    }
    
    public class SendEmailRequest {
        @InvocableVariable
        public String emailSubject;
        @InvocableVariable
        public String emailBody;
        @InvocableVariable
        public String recipientEmail;
        @InvocableVariable
        public String relatedRecordId;
    }
    
    public class SendEmailResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
        @InvocableVariable
        public String emailId;
    }
}

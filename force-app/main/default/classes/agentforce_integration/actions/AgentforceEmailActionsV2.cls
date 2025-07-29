/**
 * @description Agentforce Email Draft Actions - 통합된 이메일 생성 서비스
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceEmailActions {
    
    /**
     * 범용 이메일 초안 생성 - 단일 InvocableMethod
     */
    @InvocableMethod(label='Generate Email Draft' description='레코드 타입과 상황에 따른 이메일 초안을 생성합니다')
    public static List<EmailDraftResult> generateEmailDraft(List<UniversalEmailRequest> requests) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(UniversalEmailRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
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
    private static EmailDraftResult generateOrderEmail(UniversalEmailRequest request) {
        EmailDraftResult result = new EmailDraftResult();
        
        try {
            Order orderRecord = [
                SELECT Id, OrderNumber, Status, AccountId, Account.Name, 
                       Account.Type, TotalAmount, EffectiveDate, EndDate,
                       BillingContactId, BillingContact.Email
                FROM Order 
                WHERE Id = :request.recordId 
                LIMIT 1
            ];
            
            String subType = String.isNotBlank(request.subType) ? request.subType : 'Order_General';
            
            switch on subType {
                when 'Order_Confirmation' {
                    result.emailSubject = '[SOCAR] 주문 확인 - ' + orderRecord.OrderNumber;
                    result.emailBody = generateOrderConfirmationBody(orderRecord);
                }
                when 'Order_Activation' {
                    result.emailSubject = '[SOCAR] 서비스 활성화 완료 - ' + orderRecord.OrderNumber;
                    result.emailBody = generateOrderActivationBody(orderRecord);
                }
                when 'Order_Completion' {
                    result.emailSubject = '[SOCAR] 서비스 완료 - ' + orderRecord.OrderNumber;
                    result.emailBody = generateOrderCompletionBody(orderRecord);
                }
                when else {
                    result.emailSubject = '[SOCAR] 주문 관련 안내 - ' + orderRecord.OrderNumber;
                    result.emailBody = generateOrderGeneralBody(orderRecord);
                }
            }
            
            result.recipientEmail = orderRecord.Account.BillingEmail;
            result.success = true;
            result.emailType = 'order';
            result.relatedRecordId = request.recordId;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '주문 이메일 생성 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Payment 이메일 생성
    private static EmailDraftResult generatePaymentEmail(UniversalEmailRequest request) {
        EmailDraftResult result = new EmailDraftResult();
        
        try {
            PaymentStatus__c paymentRecord = [
                SELECT Id, Order__c, Order__r.OrderNumber, Order__r.Account.Name,
                       Order__r.Account.BillingEmail, Quarter__c, Status__c, 
                       Amount__c, Due_Date__c
                FROM PaymentStatus__c 
                WHERE Id = :request.recordId 
                LIMIT 1
            ];
            
            String subType = String.isNotBlank(request.subType) ? request.subType : 'Payment_General';
            
            switch on subType {
                when 'Payment_Reminder' {
                    result.emailSubject = '[SOCAR] 결제 안내 - ' + paymentRecord.Quarter__c + ' 분기';
                    result.emailBody = generatePaymentReminderBody(paymentRecord);
                }
                when 'Payment_Overdue' {
                    result.emailSubject = '[SOCAR] 결제 연체 알림 - ' + paymentRecord.Quarter__c + ' 분기';
                    result.emailBody = generatePaymentOverdueBody(paymentRecord);
                }
                when 'Payment_Confirmation' {
                    result.emailSubject = '[SOCAR] 결제 완료 확인 - ' + paymentRecord.Quarter__c + ' 분기';
                    result.emailBody = generatePaymentConfirmationBody(paymentRecord);
                }
                when else {
                    result.emailSubject = '[SOCAR] 결제 관련 안내 - ' + paymentRecord.Quarter__c + ' 분기';
                    result.emailBody = generatePaymentGeneralBody(paymentRecord);
                }
            }
            
            result.recipientEmail = paymentRecord.Order__r.Account.BillingEmail;
            result.success = true;
            result.emailType = 'payment';
            result.relatedRecordId = request.recordId;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '결제 이메일 생성 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Asset 이메일 생성
    private static EmailDraftResult generateAssetEmail(UniversalEmailRequest request) {
        EmailDraftResult result = new EmailDraftResult();
        
        try {
            Asset assetRecord = [
                SELECT Id, Name, AccountId, Account.Name, Account.BillingEmail,
                       Status, InstallDate, UsageEndDate, Price
                FROM Asset 
                WHERE Id = :request.recordId 
                LIMIT 1
            ];
            
            String subType = String.isNotBlank(request.subType) ? request.subType : 'Asset_General';
            
            switch on subType {
                when 'Asset_Renewal_Notice' {
                    result.emailSubject = '[SOCAR] 서비스 갱신 안내 - ' + assetRecord.Name;
                    result.emailBody = generateAssetRenewalBody(assetRecord);
                }
                when 'Asset_Expiration_Warning' {
                    result.emailSubject = '[SOCAR] 서비스 만료 예정 알림 - ' + assetRecord.Name;
                    result.emailBody = generateAssetExpirationBody(assetRecord);
                }
                when 'Asset_Maintenance' {
                    result.emailSubject = '[SOCAR] 서비스 점검 안내 - ' + assetRecord.Name;
                    result.emailBody = generateAssetMaintenanceBody(assetRecord);
                }
                when else {
                    result.emailSubject = '[SOCAR] 서비스 관련 안내 - ' + assetRecord.Name;
                    result.emailBody = generateAssetGeneralBody(assetRecord);
                }
            }
            
            result.recipientEmail = assetRecord.Account.BillingEmail;
            result.success = true;
            result.emailType = 'asset_renewal';
            result.relatedRecordId = request.recordId;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Asset 이메일 생성 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // 일반 이메일 생성
    private static EmailDraftResult generateGeneralEmail(UniversalEmailRequest request) {
        EmailDraftResult result = new EmailDraftResult();
        
        result.emailSubject = '[SOCAR] 고객 안내';
        result.emailBody = generateGeneralEmailBody(request);
        result.success = true;
        result.emailType = 'general';
        result.relatedRecordId = request.recordId;
        
        return result;
    }
    
    // 이메일 본문 생성 메소드들
    private static String generateOrderConfirmationBody(Order orderRecord) {
        return '안녕하세요 ' + orderRecord.Account.Name + ' 고객님,\n\n' +
               '주문이 성공적으로 접수되었습니다.\n\n' +
               '▶ 주문번호: ' + orderRecord.OrderNumber + '\n' +
               '▶ 주문금액: ' + String.valueOf(orderRecord.TotalAmount) + '원\n' +
               '▶ 서비스 시작일: ' + orderRecord.EffectiveDate?.format() + '\n' +
               '▶ 서비스 종료일: ' + orderRecord.EndDate?.format() + '\n\n' +
               '빠른 시일 내에 서비스 활성화를 진행하겠습니다.\n\n' +
               '문의사항이 있으시면 언제든지 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateOrderActivationBody(Order orderRecord) {
        return '안녕하세요 ' + orderRecord.Account.Name + ' 고객님,\n\n' +
               '주문하신 서비스가 정상적으로 활성화되었습니다.\n\n' +
               '▶ 주문번호: ' + orderRecord.OrderNumber + '\n' +
               '▶ 활성화 완료일: ' + Date.today().format() + '\n\n' +
               '이제 SOCAR B2B 서비스를 이용하실 수 있습니다.\n' +
               '서비스 이용 방법에 대한 안내를 별도로 발송해드리겠습니다.\n\n' +
               '문의사항이 있으시면 언제든지 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateOrderCompletionBody(Order orderRecord) {
        return '안녕하세요 ' + orderRecord.Account.Name + ' 고객님,\n\n' +
               '주문하신 서비스가 성공적으로 완료되었습니다.\n\n' +
               '▶ 주문번호: ' + orderRecord.OrderNumber + '\n' +
               '▶ 완료일: ' + Date.today().format() + '\n\n' +
               '서비스 이용에 만족하셨나요?\n' +
               '고객님의 소중한 의견을 듣고 싶습니다.\n\n' +
               '향후 서비스 갱신이나 추가 서비스에 대해서도\n' +
               '언제든지 문의해 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateOrderGeneralBody(Order orderRecord) {
        return '안녕하세요 ' + orderRecord.Account.Name + ' 고객님,\n\n' +
               '주문 ' + orderRecord.OrderNumber + '에 대한 안내입니다.\n\n' +
               '추가 정보나 문의사항이 있으시면\n' +
               '언제든지 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generatePaymentReminderBody(PaymentStatus__c paymentRecord) {
        return '안녕하세요 ' + paymentRecord.Order__r.Account.Name + ' 고객님,\n\n' +
               paymentRecord.Quarter__c + ' 분기 결제 안내입니다.\n\n' +
               '▶ 결제 금액: ' + String.valueOf(paymentRecord.Amount__c) + '원\n' +
               '▶ 결제 기한: ' + paymentRecord.Due_Date__c?.format() + '\n\n' +
               '기한 내 결제 부탁드립니다.\n\n' +
               '결제 관련 문의사항이 있으시면 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generatePaymentOverdueBody(PaymentStatus__c paymentRecord) {
        return '안녕하세요 ' + paymentRecord.Order__r.Account.Name + ' 고객님,\n\n' +
               paymentRecord.Quarter__c + ' 분기 결제가 연체되었습니다.\n\n' +
               '▶ 결제 금액: ' + String.valueOf(paymentRecord.Amount__c) + '원\n' +
               '▶ 연체일: ' + Date.today().format() + '\n\n' +
               '빠른 시일 내에 결제 부탁드립니다.\n' +
               '서비스 중단을 방지하기 위해 즉시 연락 주세요.\n\n' +
               '긴급 연락처: 02-1234-5678\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generatePaymentConfirmationBody(PaymentStatus__c paymentRecord) {
        return '안녕하세요 ' + paymentRecord.Order__r.Account.Name + ' 고객님,\n\n' +
               paymentRecord.Quarter__c + ' 분기 결제가 정상적으로 완료되었습니다.\n\n' +
               '▶ 결제 금액: ' + String.valueOf(paymentRecord.Amount__c) + '원\n' +
               '▶ 결제 완료일: ' + Date.today().format() + '\n\n' +
               '결제해 주셔서 감사합니다.\n' +
               '계속해서 안정적인 서비스를 제공하겠습니다.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generatePaymentGeneralBody(PaymentStatus__c paymentRecord) {
        return '안녕하세요 ' + paymentRecord.Order__r.Account.Name + ' 고객님,\n\n' +
               paymentRecord.Quarter__c + ' 분기 결제 관련 안내입니다.\n\n' +
               '문의사항이 있으시면 언제든지 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateAssetRenewalBody(Asset assetRecord) {
        return '안녕하세요 ' + assetRecord.Account.Name + ' 고객님,\n\n' +
               '서비스 갱신 시기가 다가왔습니다.\n\n' +
               '▶ 서비스명: ' + assetRecord.Name + '\n' +
               '▶ 만료 예정일: ' + assetRecord.UsageEndDate?.format() + '\n\n' +
               '서비스 연장을 원하시면 연락 주세요.\n' +
               '더 나은 조건으로 갱신 가능합니다.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateAssetExpirationBody(Asset assetRecord) {
        return '안녕하세요 ' + assetRecord.Account.Name + ' 고객님,\n\n' +
               '서비스 만료가 임박했습니다.\n\n' +
               '▶ 서비스명: ' + assetRecord.Name + '\n' +
               '▶ 만료일: ' + assetRecord.UsageEndDate?.format() + '\n\n' +
               '서비스 중단을 방지하려면 갱신이 필요합니다.\n' +
               '즉시 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateAssetMaintenanceBody(Asset assetRecord) {
        return '안녕하세요 ' + assetRecord.Account.Name + ' 고객님,\n\n' +
               '서비스 점검 안내입니다.\n\n' +
               '▶ 서비스명: ' + assetRecord.Name + '\n' +
               '▶ 점검일: ' + Date.today().addDays(7).format() + '\n\n' +
               '점검 중 일시적으로 서비스가 중단될 수 있습니다.\n' +
               '양해 부탁드립니다.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateAssetGeneralBody(Asset assetRecord) {
        return '안녕하세요 ' + assetRecord.Account.Name + ' 고객님,\n\n' +
               '서비스 ' + assetRecord.Name + ' 관련 안내입니다.\n\n' +
               '문의사항이 있으시면 언제든지 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    private static String generateGeneralEmailBody(UniversalEmailRequest request) {
        return '안녕하세요,\n\n' +
               'SOCAR B2B 영업팀입니다.\n\n' +
               (String.isNotBlank(request.additionalContext) ? 
                request.additionalContext + '\n\n' : '') +
               '문의사항이 있으시면 언제든지 연락 주세요.\n\n' +
               '감사합니다.\n' +
               'SOCAR B2B 영업팀';
    }
    
    // Wrapper Classes
    public class UniversalEmailRequest {
        @InvocableVariable(label='Record ID' required=true)
        public String recordId;
        
        @InvocableVariable(label='Email Type' required=true)
        public String emailType; // order, payment, asset_renewal, general
        
        @InvocableVariable(label='Sub Type')
        public String subType; // Order_Confirmation, Payment_Reminder, etc.
        
        @InvocableVariable(label='Additional Context')
        public String additionalContext;
        
        @InvocableVariable(label='Recipient Email Override')
        public String recipientEmailOverride;
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
        public String emailType;
        
        @InvocableVariable
        public String relatedRecordId;
        
        @InvocableVariable
        public String errorMessage;
        
        public EmailDraftResult() {
            this.success = false;
        }
    }
    
    // 기존 코드와의 호환성을 위한 래퍼 클래스들
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
    
    public class SendEmailRequest {
        @InvocableVariable
        public String emailSubject;
        @InvocableVariable
        public String emailBody;
        @InvocableVariable
        public String recipientEmail;
        @InvocableVariable
        public String relatedRecordId;
        @InvocableVariable
        public String senderDisplayName;
    }
    
    public class SendEmailResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
        @InvocableVariable
        public String emailId;
        @InvocableVariable
        public String activityId;
    }
}

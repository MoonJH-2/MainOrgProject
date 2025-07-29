/**
 * @description Agentforce와 기존 이메일 시스템을 연결하는 통합 서비스
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceEmailIntegrationService {
    
    /**
     * Agentforce에서 호출되는 통합 이메일 작성 메서드
     */
    @InvocableMethod(label='Generate Smart Email' description='Agentforce를 통한 스마트 이메일 생성')
    public static List<EmailGenerationResult> generateSmartEmail(List<EmailGenerationRequest> requests) {
        List<EmailGenerationResult> results = new List<EmailGenerationResult>();
        
        for (EmailGenerationRequest request : requests) {
            try {
                EmailGenerationResult result = processEmailRequest(request);
                results.add(result);
            } catch (Exception e) {
                EmailGenerationResult errorResult = new EmailGenerationResult();
                errorResult.success = false;
                errorResult.errorMessage = e.getMessage();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    private static EmailGenerationResult processEmailRequest(EmailGenerationRequest request) {
        EmailGenerationResult result = new EmailGenerationResult();
        
        // 1. 기존 AgentforceEmailActions 호출
        switch on request.emailType.toLowerCase() {
            when 'order' {
                result = generateOrderEmail(request);
            }
            when 'payment' {
                result = generatePaymentEmail(request);
            }
            when 'asset_renewal' {
                result = generateAssetRenewalEmail(request);
            }
            when else {
                result = generateGeneralEmail(request);
            }
        }
        
        // 2. Agentforce 추천 정보 통합
        if (String.isNotBlank(request.agentforceRecommendations)) {
            result = enhanceWithAgentforceInsights(result, request.agentforceRecommendations);
        }
        
        // 3. 성공 처리
        result.success = true;
        result.timestamp = System.now();
        
        return result;
    }
    
    private static EmailGenerationResult generateOrderEmail(EmailGenerationRequest request) {
        // AgentforceEmailActions.draftOrderEmail 호출
        AgentforceEmailActions.OrderEmailRequest orderRequest = new AgentforceEmailActions.OrderEmailRequest();
        orderRequest.orderId = request.recordId;
        orderRequest.emailType = request.subType != null ? request.subType : 'Order_Confirmation';
        
        List<AgentforceEmailActions.OrderEmailRequest> orderRequests = 
            new List<AgentforceEmailActions.OrderEmailRequest>{orderRequest};
        
        List<AgentforceEmailActions.EmailDraftResult> orderResults = 
            AgentforceEmailActions.draftOrderEmail(orderRequests);
        
        return convertToEmailGenerationResult(orderResults[0], 'Order');
    }
    
    private static EmailGenerationResult generatePaymentEmail(EmailGenerationRequest request) {
        // AgentforceEmailActions.draftPaymentEmail 호출
        AgentforceEmailActions.PaymentEmailRequest paymentRequest = new AgentforceEmailActions.PaymentEmailRequest();
        paymentRequest.paymentId = request.recordId;
        paymentRequest.emailType = request.subType != null ? request.subType : 'Payment_Reminder';
        
        List<AgentforceEmailActions.PaymentEmailRequest> paymentRequests = 
            new List<AgentforceEmailActions.PaymentEmailRequest>{paymentRequest};
        
        List<AgentforceEmailActions.EmailDraftResult> paymentResults = 
            AgentforceEmailActions.draftPaymentEmail(paymentRequests);
        
        return convertToEmailGenerationResult(paymentResults[0], 'Payment');
    }
    
    private static EmailGenerationResult generateAssetRenewalEmail(EmailGenerationRequest request) {
        // AgentforceEmailActions.draftAssetRenewalEmail 호출
        AgentforceEmailActions.AssetEmailRequest assetRequest = new AgentforceEmailActions.AssetEmailRequest();
        assetRequest.assetId = request.recordId;
        assetRequest.emailType = request.subType != null ? request.subType : 'Renewal_Reminder';
        
        List<AgentforceEmailActions.AssetEmailRequest> assetRequests = 
            new List<AgentforceEmailActions.AssetEmailRequest>{assetRequest};
        
        List<AgentforceEmailActions.EmailDraftResult> assetResults = 
            AgentforceEmailActions.draftAssetRenewalEmail(assetRequests);
        
        return convertToEmailGenerationResult(assetResults[0], 'Asset Renewal');
    }
    
    private static EmailGenerationResult generateGeneralEmail(EmailGenerationRequest request) {
        EmailGenerationResult result = new EmailGenerationResult();
        
        // 기본 이메일 템플릿 생성
        result.emailSubject = request.customSubject != null ? 
            request.customSubject : '[SOCAR] 안녕하세요';
        
        result.emailBody = '안녕하세요,\n\n' +
            'SOCAR B2B 서비스 관련하여 연락드립니다.\n\n' +
            (String.isNotBlank(request.customMessage) ? request.customMessage + '\n\n' : '') +
            '추가 문의사항이 있으시면 언제든 연락 주시기 바랍니다.\n\n' +
            '감사합니다.\n' +
            'SOCAR B2B 팀';
        
        result.emailType = 'General';
        
        return result;
    }
    
    private static EmailGenerationResult convertToEmailGenerationResult(
        AgentforceEmailActions.EmailDraftResult draftResult, String emailType) {
        
        EmailGenerationResult result = new EmailGenerationResult();
        result.emailSubject = draftResult.emailSubject;
        result.emailBody = draftResult.emailBody;
        result.recipientEmail = draftResult.recipientEmail;
        result.emailType = emailType;
        result.originalDraftId = draftResult.draftId;
        
        return result;
    }
    
    private static EmailGenerationResult enhanceWithAgentforceInsights(
        EmailGenerationResult original, String recommendations) {
        
        // Agentforce 추천사항을 이메일에 통합
        if (String.isNotBlank(recommendations)) {
            original.emailBody = original.emailBody + '\n\n--- AI 추천 ---\n' + recommendations;
            original.agentforceEnhanced = true;
        }
        
        return original;
    }
    
    /**
     * 생성된 이메일을 실제로 전송
     */
    @AuraEnabled
    public static SendEmailResult sendGeneratedEmail(SendEmailRequest request) {
        try {
            // AgentforceEmailActions.sendGeneratedEmail 호출
            AgentforceEmailActions.SendEmailRequest sendRequest = new AgentforceEmailActions.SendEmailRequest();
            sendRequest.emailSubject = request.emailSubject;
            sendRequest.emailBody = request.emailBody;
            sendRequest.recipientEmail = request.recipientEmail;
            sendRequest.senderName = request.senderName;
            sendRequest.recordId = request.recordId;
            
            List<AgentforceEmailActions.SendEmailRequest> sendRequests = 
                new List<AgentforceEmailActions.SendEmailRequest>{sendRequest};
            
            List<AgentforceEmailActions.SendEmailResult> sendResults = 
                AgentforceEmailActions.sendGeneratedEmail(sendRequests);
            
            // 결과 변환
            SendEmailResult result = new SendEmailResult();
            result.success = sendResults[0].success;
            result.message = sendResults[0].message;
            result.emailId = sendResults[0].emailId;
            result.activityId = sendResults[0].activityId;
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('이메일 전송 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * Agentforce Agent에서 사용할 수 있는 이메일 통계 조회
     */
    @AuraEnabled(cacheable=true)
    public static EmailAnalyticsResult getEmailAnalytics(Id userId, Integer days) {
        try {
            EmailAnalyticsResult result = new EmailAnalyticsResult();
            
            Date fromDate = Date.today().addDays(-days);
            
            // 발송된 이메일 수 조회
            List<EmailMessage> sentEmails = [
                SELECT Id, CreatedDate, Subject, Status
                FROM EmailMessage 
                WHERE CreatedById = :userId 
                AND CreatedDate >= :fromDate
                AND Incoming = false
            ];
            
            result.totalEmailsSent = sentEmails.size();
            result.successfulSends = 0;
            result.failedSends = 0;
            
            for (EmailMessage email : sentEmails) {
                if (email.Status == '3') { // Sent
                    result.successfulSends++;
                } else {
                    result.failedSends++;
                }
            }
            
            // 응답률 계산 (단순화)
            result.responseRate = result.totalEmailsSent > 0 ? 
                (result.successfulSends * 100 / result.totalEmailsSent) : 0;
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('이메일 분석 조회 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // Wrapper Classes for Agentforce Integration
    
    public class EmailGenerationRequest {
        @InvocableVariable(label='Record ID' required=true)
        public String recordId;
        
        @InvocableVariable(label='Email Type' required=true)
        public String emailType; // order, payment, asset_renewal, general
        
        @InvocableVariable(label='Email Sub Type')
        public String subType; // Order_Confirmation, Payment_Reminder, etc.
        
        @InvocableVariable(label='Custom Subject')
        public String customSubject;
        
        @InvocableVariable(label='Custom Message')
        public String customMessage;
        
        @InvocableVariable(label='Agentforce Recommendations')
        public String agentforceRecommendations;
        
        @InvocableVariable(label='Urgency Level')
        public String urgencyLevel; // low, normal, high
    }
    
    public class EmailGenerationResult {
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
        public String errorMessage;
        
        @InvocableVariable
        public DateTime timestamp;
        
        @InvocableVariable
        public String originalDraftId;
        
        @InvocableVariable
        public Boolean agentforceEnhanced;
        
        public EmailGenerationResult() {
            this.success = false;
            this.agentforceEnhanced = false;
        }
    }
    
    public class SendEmailRequest {
        @AuraEnabled public String emailSubject { get; set; }
        @AuraEnabled public String emailBody { get; set; }
        @AuraEnabled public String recipientEmail { get; set; }
        @AuraEnabled public String senderName { get; set; }
        @AuraEnabled public String recordId { get; set; }
    }
    
    public class SendEmailResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String emailId { get; set; }
        @AuraEnabled public String activityId { get; set; }
    }
    
    public class EmailAnalyticsResult {
        @AuraEnabled public Integer totalEmailsSent { get; set; }
        @AuraEnabled public Integer successfulSends { get; set; }
        @AuraEnabled public Integer failedSends { get; set; }
        @AuraEnabled public Decimal responseRate { get; set; }
        
        public EmailAnalyticsResult() {
            this.totalEmailsSent = 0;
            this.successfulSends = 0;
            this.failedSends = 0;
            this.responseRate = 0;
        }
    }
}

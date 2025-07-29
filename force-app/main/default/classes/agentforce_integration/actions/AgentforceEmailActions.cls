/**
 * @description Agentforce Email Draft Actions for Order, PaymentStatus, Asset
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
    
    // Order 이메일 생성 (기존 로직을 private method로 변환)
    private static EmailDraftResult generateOrderEmail(UniversalEmailRequest request) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(OrderEmailRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
            try {
                // Order 정보 조회
                Order orderRecord = [
                    SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate,
                           Account.Name, Account.BillingStreet, Account.BillingCity,
                           Owner.Name, Owner.Email, Owner.Phone
                    FROM Order 
                    WHERE Id = :request.orderId 
                    LIMIT 1
                ];
                
                // 이메일 템플릿 생성
                String emailSubject = generateOrderEmailSubject(orderRecord, request.emailType);
                String emailBody = generateOrderEmailBody(orderRecord, request.emailType);
                
                result.emailSubject = emailSubject;
                result.emailBody = emailBody;
                result.recipientEmail = getOrderRecipientEmail(orderRecord);
                result.emailType = request.emailType;
                result.orderNumber = orderRecord.OrderNumber;
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = 'Order 이메일 생성 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * Payment 알림 이메일 초안 생성
     */
    @InvocableMethod(label='Draft Payment Email' description='Payment 상태에 따른 알림 이메일 초안을 생성합니다')
    public static List<EmailDraftResult> draftPaymentEmail(List<PaymentEmailRequest> requests) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(PaymentEmailRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
            try {
                // PaymentStatus 정보 조회
                List<SObject> paymentRecords = Database.query(
                    'SELECT Id, Name, Order__c, Order__r.OrderNumber, Order__r.Account.Name, ' +
                    'Amount__c, DueDate__c, Status__c, Installment_Number__c, ' +
                    'Order__r.Owner.Name, Order__r.Owner.Email ' +
                    'FROM PaymentStatus__c WHERE Id = :request.paymentId LIMIT 1'
                );
                
                if(paymentRecords.isEmpty()) {
                    result.success = false;
                    result.errorMessage = 'PaymentStatus를 찾을 수 없습니다.';
                    results.add(result);
                    continue;
                }
                
                SObject paymentRecord = paymentRecords[0];
                
                // 이메일 템플릿 생성
                String emailSubject = generatePaymentEmailSubject(paymentRecord, request.emailType);
                String emailBody = generatePaymentEmailBody(paymentRecord, request.emailType);
                
                result.emailSubject = emailSubject;
                result.emailBody = emailBody;
                result.recipientEmail = getPaymentRecipientEmail(paymentRecord);
                result.emailType = request.emailType;
                result.orderNumber = (String)paymentRecord.get('Order__r.OrderNumber');
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = 'Payment 이메일 생성 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * Asset 갱신 이메일 초안 생성
     */
    @InvocableMethod(label='Draft Asset Renewal Email' description='Asset 갱신 관련 이메일 초안을 생성합니다')
    public static List<EmailDraftResult> draftAssetRenewalEmail(List<AssetEmailRequest> requests) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(AssetEmailRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
            try {
                // Asset 정보 조회
                Asset assetRecord = [
                    SELECT Id, Name, Status, InstallDate, UsageEndDate,
                           Account.Name, Account.BillingStreet, Account.BillingCity,
                           Account.Owner.Name, Account.Owner.Email
                    FROM Asset 
                    WHERE Id = :request.assetId 
                    LIMIT 1
                ];
                
                // 이메일 템플릿 생성
                String emailSubject = generateAssetEmailSubject(assetRecord, request.emailType);
                String emailBody = generateAssetEmailBody(assetRecord, request.emailType);
                
                result.emailSubject = emailSubject;
                result.emailBody = emailBody;
                result.recipientEmail = getAssetRecipientEmail(assetRecord);
                result.emailType = request.emailType;
                result.assetName = assetRecord.Name;
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = 'Asset 이메일 생성 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * 통합 이메일 수정 기능
     */
    @InvocableMethod(label='Revise Email Draft' description='기존 이메일 초안을 수정합니다')
    public static List<EmailDraftResult> reviseEmailDraft(List<EmailRevisionRequest> requests) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(EmailRevisionRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
            try {
                // 기존 이메일 내용 기반으로 수정
                String revisedSubject = reviseEmailSubject(request.originalSubject, request.revisionInstructions);
                String revisedBody = reviseEmailBody(request.originalBody, request.revisionInstructions);
                
                result.emailSubject = revisedSubject;
                result.emailBody = revisedBody;
                result.recipientEmail = request.recipientEmail;
                result.emailType = 'Revised';
                result.revisionNotes = generateRevisionNotes(request.revisionInstructions);
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = '이메일 수정 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Helper Methods for Order Emails
    private static String generateOrderEmailSubject(Order orderRecord, String emailType) {
        String subject = '';
        
        switch on emailType {
            when 'Order_Confirmation' {
                subject = '[주문 확인] Order ' + orderRecord.OrderNumber + ' - ' + orderRecord.Account.Name;
            }
            when 'Order_Activation' {
                subject = '[서비스 활성화] Order ' + orderRecord.OrderNumber + ' 서비스가 시작되었습니다';
            }
            when 'Order_Status_Update' {
                subject = '[진행 상황] Order ' + orderRecord.OrderNumber + ' 상태 업데이트';
            }
            when 'Order_Completion' {
                subject = '[완료 알림] Order ' + orderRecord.OrderNumber + ' 서비스 완료';
            }
            when else {
                subject = '[알림] Order ' + orderRecord.OrderNumber + ' 관련 안내';
            }
        }
        
        return subject;
    }
    
    private static String generateOrderEmailBody(Order orderRecord, String emailType) {
        String body = '';
        
        body += '안녕하세요, ' + orderRecord.Account.Name + ' 담당자님\n\n';
        body += '담당 영업사원 ' + orderRecord.Owner.Name + '입니다.\n\n';
        
        switch on emailType {
            when 'Order_Confirmation' {
                body += '📋 주문이 정상적으로 접수되었습니다.\n\n';
                body += '주문 정보:\n';
                body += '• 주문번호: ' + orderRecord.OrderNumber + '\n';
                body += '• 주문금액: ₩' + String.valueOf(orderRecord.TotalAmount) + '\n';
                body += '• 시작일: ' + orderRecord.EffectiveDate.format() + '\n\n';
                body += '추가 문의사항이 있으시면 언제든 연락주세요.\n';
            }
            when 'Order_Activation' {
                body += '🚀 서비스가 정상적으로 활성화되었습니다.\n\n';
                body += '이제 주문하신 서비스를 이용하실 수 있습니다.\n';
                body += '서비스 이용 중 문의사항이 있으시면 담당자에게 연락주세요.\n';
            }
            when 'Order_Status_Update' {
                body += '📊 주문 진행 상황을 안내드립니다.\n\n';
                body += '현재 상태: ' + orderRecord.Status + '\n';
                body += '다음 단계 진행 시 별도 안내드리겠습니다.\n';
            }
            when 'Order_Completion' {
                body += '🎉 주문이 성공적으로 완료되었습니다.\n\n';
                body += '서비스 이용해 주셔서 감사합니다.\n';
                body += '추가 서비스나 연장이 필요하시면 언제든 문의주세요.\n';
            }
        }
        
        body += '\n감사합니다.\n';
        body += orderRecord.Owner.Name + '\n';
        body += '전화: ' + orderRecord.Owner.Phone + '\n';
        body += '이메일: ' + orderRecord.Owner.Email;
        
        return body;
    }
    
    // Helper Methods for Payment Emails
    private static String generatePaymentEmailSubject(SObject paymentRecord, String emailType) {
        String orderNumber = (String)paymentRecord.get('Order__r.OrderNumber');
        String subject = '';
        
        switch on emailType {
            when 'Payment_Reminder' {
                subject = '[결제 안내] Order ' + orderNumber + ' - ' + paymentRecord.get('Installment_Number__c') + '회차 결제 안내';
            }
            when 'Payment_Overdue' {
                subject = '[연체 알림] Order ' + orderNumber + ' - 결제 지연 안내';
            }
            when 'Payment_Confirmation' {
                subject = '[결제 완료] Order ' + orderNumber + ' - 결제가 완료되었습니다';
            }
            when else {
                subject = '[결제 알림] Order ' + orderNumber + ' 결제 관련 안내';
            }
        }
        
        return subject;
    }
    
    private static String generatePaymentEmailBody(SObject paymentRecord, String emailType) {
        String body = '';
        String accountName = (String)paymentRecord.get('Order__r.Account.Name');
        String orderNumber = (String)paymentRecord.get('Order__r.OrderNumber');
        String ownerName = (String)paymentRecord.get('Order__r.Owner.Name');
        
        body += '안녕하세요, ' + accountName + ' 담당자님\n\n';
        body += '담당 영업사원 ' + ownerName + '입니다.\n\n';
        
        switch on emailType {
            when 'Payment_Reminder' {
                Date dueDate = (Date)paymentRecord.get('DueDate__c');
                Decimal amount = (Decimal)paymentRecord.get('Amount__c');
                
                body += '💰 결제 예정 안내드립니다.\n\n';
                body += '결제 정보:\n';
                body += '• 주문번호: ' + orderNumber + '\n';
                body += '• 회차: ' + paymentRecord.get('Installment_Number__c') + '회차\n';
                body += '• 결제금액: ₩' + String.valueOf(amount) + '\n';
                body += '• 결제예정일: ' + dueDate.format() + '\n\n';
                body += '결제일 3일 전 안내드리며, 준비해 주시기 바랍니다.\n';
            }
            when 'Payment_Overdue' {
                body += '⚠️ 결제가 지연되어 안내드립니다.\n\n';
                body += '빠른 시일 내에 결제를 완료해 주시기 바라며,\n';
                body += '결제 관련 문의사항이 있으시면 담당자에게 연락주세요.\n';
            }
            when 'Payment_Confirmation' {
                body += '✅ 결제가 정상적으로 완료되었습니다.\n\n';
                body += '결제해 주셔서 감사합니다.\n';
                body += '다음 회차 결제일이 다가오면 미리 안내드리겠습니다.\n';
            }
        }
        
        body += '\n감사합니다.\n';
        body += ownerName + '\n';
        body += '문의: ' + paymentRecord.get('Order__r.Owner.Email');
        
        return body;
    }
    
    // Helper Methods for Asset Emails
    private static String generateAssetEmailSubject(Asset assetRecord, String emailType) {
        String subject = '';
        
        switch on emailType {
            when 'Asset_Renewal_Notice' {
                subject = '[갱신 안내] ' + assetRecord.Name + ' 갱신 시기 안내';
            }
            when 'Asset_Expiration_Warning' {
                subject = '[만료 예정] ' + assetRecord.Name + ' 서비스 만료 안내';
            }
            when 'Asset_Renewal_Offer' {
                subject = '[갱신 제안] ' + assetRecord.Name + ' 특별 갱신 혜택';
            }
            when else {
                subject = '[Asset 알림] ' + assetRecord.Name + ' 관련 안내';
            }
        }
        
        return subject;
    }
    
    private static String generateAssetEmailBody(Asset assetRecord, String emailType) {
        String body = '';
        
        body += '안녕하세요, ' + assetRecord.Account.Name + ' 담당자님\n\n';
        body += '담당 영업사원 ' + assetRecord.Account.Owner.Name + '입니다.\n\n';
        
        switch on emailType {
            when 'Asset_Renewal_Notice' {
                Integer daysToExpiry = Date.today().daysBetween(assetRecord.UsageEndDate);
                
                body += '🔄 Asset 갱신 시기가 다가와 안내드립니다.\n\n';
                body += 'Asset 정보:\n';
                body += '• Asset명: ' + assetRecord.Name + '\n';
                body += '• 현재 상태: ' + assetRecord.Status + '\n';
                body += '• 만료예정일: ' + assetRecord.UsageEndDate.format() + '\n';
                body += '• 남은 기간: ' + daysToExpiry + '일\n\n';
                body += '서비스 연장을 희망하시면 미리 연락주시기 바랍니다.\n';
            }
            when 'Asset_Expiration_Warning' {
                body += '⚠️ Asset 서비스 만료가 임박했습니다.\n\n';
                body += '서비스 중단을 피하려면 갱신 절차를 진행해 주세요.\n';
                body += '갱신 관련 문의사항이 있으시면 언제든 연락주세요.\n';
            }
            when 'Asset_Renewal_Offer' {
                body += '🎁 특별 갱신 혜택을 제안드립니다.\n\n';
                body += '기존 고객 대상 할인 혜택과 추가 서비스를\n';
                body += '제공해 드릴 수 있습니다.\n\n';
                body += '자세한 내용은 담당자와 상담해 주세요.\n';
            }
        }
        
        body += '\n감사합니다.\n';
        body += assetRecord.Account.Owner.Name + '\n';
        body += '이메일: ' + assetRecord.Account.Owner.Email;
        
        return body;
    }
    
    // Email Revision Helper Methods
    private static String reviseEmailSubject(String originalSubject, String instructions) {
        String revisedSubject = originalSubject;
        
        if(instructions.containsIgnoreCase('urgent') || instructions.containsIgnoreCase('긴급')) {
            revisedSubject = '[긴급] ' + revisedSubject;
        }
        
        if(instructions.containsIgnoreCase('reminder') || instructions.containsIgnoreCase('리마인더')) {
            revisedSubject = revisedSubject.replace('[알림]', '[리마인더]');
        }
        
        return revisedSubject;
    }
    
    private static String reviseEmailBody(String originalBody, String instructions) {
        String revisedBody = originalBody;
        
        if(instructions.containsIgnoreCase('formal') || instructions.containsIgnoreCase('공식적')) {
            revisedBody = revisedBody.replace('안녕하세요', '안녕하십니까');
            revisedBody = revisedBody.replace('주세요', '주시기 바랍니다');
        }
        
        if(instructions.containsIgnoreCase('brief') || instructions.containsIgnoreCase('간단')) {
            // 간단하게 요약
            String[] lines = revisedBody.split('\n');
            String briefBody = '';
            for(String line : lines) {
                if(line.contains('•') || line.contains('📋') || line.contains('💰') || line.contains('🔄')) {
                    briefBody += line + '\n';
                }
            }
            revisedBody = briefBody;
        }
        
        return revisedBody;
    }
    
    private static String getOrderRecipientEmail(Order orderRecord) {
        // 실제 구현에서는 Contact 또는 Account에서 이메일 조회
        return 'customer@example.com'; // placeholder
    }
    
    private static String getPaymentRecipientEmail(SObject paymentRecord) {
        // 실제 구현에서는 Account Contact에서 이메일 조회
        return 'finance@example.com'; // placeholder
    }
    
    private static String getAssetRecipientEmail(Asset assetRecord) {
        // 실제 구현에서는 Account Contact에서 이메일 조회
        return 'admin@example.com'; // placeholder
    }
    
    private static String generateRevisionNotes(String instructions) {
        return '수정 요청: ' + instructions + ' (수정 시간: ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ')';
    }
    
    // Input/Output Classes
    public class OrderEmailRequest {
        @InvocableVariable(required=true)
        public String orderId;
        @InvocableVariable(required=true)
        public String emailType; // Order_Confirmation, Order_Activation, Order_Status_Update, Order_Completion
    }
    
    public class PaymentEmailRequest {
        @InvocableVariable(required=true)
        public String paymentId;
        @InvocableVariable(required=true)
        public String emailType; // Payment_Reminder, Payment_Overdue, Payment_Confirmation
    }
    
    public class AssetEmailRequest {
        @InvocableVariable(required=true)
        public String assetId;
        @InvocableVariable(required=true)
        public String emailType; // Asset_Renewal_Notice, Asset_Expiration_Warning, Asset_Renewal_Offer
    }
    
    public class EmailRevisionRequest {
        @InvocableVariable(required=true)
        public String originalSubject;
        @InvocableVariable(required=true)
        public String originalBody;
        @InvocableVariable(required=true)
        public String revisionInstructions;
        @InvocableVariable
        public String recipientEmail;
    }
    
    public class EmailDraftResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String emailSubject;
        @InvocableVariable
        public String emailBody;
        @InvocableVariable
        public String recipientEmail;
        @InvocableVariable
        public String emailType;
        @InvocableVariable
        public String orderNumber;
        @InvocableVariable
        public String assetName;
        @InvocableVariable
        public String revisionNotes;
    }
}

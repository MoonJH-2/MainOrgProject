/**
 * @description Agentforce Payment Email Draft Action
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforcePaymentEmailAction {
    
    /**
     * Payment 알림 이메일 초안 생성
     */
    @InvocableMethod(label='Draft Payment Email' description='Payment 상태에 따른 알림 이메일 초안을 생성합니다')
    public static List<EmailDraftResult> draftPaymentEmail(List<PaymentEmailRequest> requests) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(PaymentEmailRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
            try {
                // PaymentStatus 정보 조회 - PaymentStatus ID 또는 Name으로 검색
                List<SObject> paymentRecords = new List<SObject>();
                
                // 먼저 PaymentStatus ID로 시도
                if(request.paymentId.length() >= 15) {
                    paymentRecords = Database.query(
                        'SELECT Id, Name, Order__c, Order__r.OrderNumber, Order__r.Account.Name, ' +
                        'Amount__c, DueDate__c, Status__c, Installment_Number__c, ' +
                        'Order__r.Owner.Name, Order__r.Owner.Email ' +
                        'FROM PaymentStatus__c WHERE Id = :request.paymentId LIMIT 1'
                    );
                }
                
                // PaymentStatus ID로 찾지 못했으면 Name으로 검색
                if(paymentRecords.isEmpty()) {
                    paymentRecords = Database.query(
                        'SELECT Id, Name, Order__c, Order__r.OrderNumber, Order__r.Account.Name, ' +
                        'Amount__c, DueDate__c, Status__c, Installment_Number__c, ' +
                        'Order__r.Owner.Name, Order__r.Owner.Email ' +
                        'FROM PaymentStatus__c WHERE Name = :request.paymentId LIMIT 1'
                    );
                }
                
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
    
    // Helper Methods
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
    
    private static String getPaymentRecipientEmail(SObject paymentRecord) {
        // 실제 구현에서는 Account Contact에서 이메일 조회
        return 'finance@example.com'; // placeholder
    }
    
    // Input/Output Classes
    public class PaymentEmailRequest {
        @InvocableVariable(required=true)
        public String paymentId;
        @InvocableVariable(required=true)
        public String emailType; // Payment_Reminder, Payment_Overdue, Payment_Confirmation
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
    }
}

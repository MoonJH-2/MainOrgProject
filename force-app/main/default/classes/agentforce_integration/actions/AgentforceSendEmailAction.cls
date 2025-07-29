/**
 * @description Agentforce Send Email Action
 * @author AI Assistant  
 * @created 2025-07-24
 */
public with sharing class AgentforceSendEmailAction {
    
    /**
     * 생성된 이메일 초안을 실제로 전송
     */
    @InvocableMethod(label='Send Generated Email' description='생성된 이메일 초안을 실제로 전송합니다')
    public static List<EmailSendResult> sendGeneratedEmail(List<EmailSendRequest> requests) {
        List<EmailSendResult> results = new List<EmailSendResult>();
        
        for(EmailSendRequest request : requests) {
            EmailSendResult result = new EmailSendResult();
            
            try {
                // SingleEmailMessage 생성
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                // 이메일 기본 설정
                email.setSubject(request.emailSubject);
                email.setPlainTextBody(request.emailBody);
                email.setHtmlBody(convertToHtml(request.emailBody));
                
                // 수신자 설정
                List<String> toAddresses = new List<String>{request.recipientEmail};
                email.setToAddresses(toAddresses);
                
                // 관련 레코드 설정 (Activity History에 저장)
                if(String.isNotEmpty(request.relatedRecordId)) {
                    email.setWhatId(request.relatedRecordId);
                }
                
                // 발신자 설정 (조직 기본 이메일 사용)
                email.setSaveAsActivity(true);
                email.setUseSignature(true);
                
                // 이메일 전송
                Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                
                if(sendResults[0].isSuccess()) {
                    result.success = true;
                    result.emailId = String.valueOf(sendResults[0]);
                    result.message = '이메일이 성공적으로 전송되었습니다.';
                    result.recipientEmail = request.recipientEmail;
                } else {
                    result.success = false;
                    result.errorMessage = '이메일 전송 실패: ' + sendResults[0].getErrors()[0].getMessage();
                }
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = '이메일 전송 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * 텍스트를 HTML로 변환
     */
    private static String convertToHtml(String plainText) {
        if(String.isEmpty(plainText)) return '';
        
        String htmlBody = plainText;
        // 줄바꿈을 <br> 태그로 변환
        htmlBody = htmlBody.replace('\n', '<br>');
        // 이모지 및 특수문자 보존
        htmlBody = '<html><body style="font-family: Arial, sans-serif; font-size: 14px;">' + 
                   htmlBody + '</body></html>';
        
        return htmlBody;
    }
    
    // Input/Output Classes
    public class EmailSendRequest {
        @InvocableVariable(required=true)
        public String emailSubject;
        @InvocableVariable(required=true) 
        public String emailBody;
        @InvocableVariable(required=true)
        public String recipientEmail;
        @InvocableVariable
        public String relatedRecordId; // Order ID, Payment ID 등
        @InvocableVariable
        public String senderName;
    }
    
    public class EmailSendResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String emailId;
        @InvocableVariable
        public String recipientEmail;
    }
}

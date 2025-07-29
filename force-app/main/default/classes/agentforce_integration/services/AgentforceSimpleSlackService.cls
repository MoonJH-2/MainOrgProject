/**
 * @description Agentforce Slack 통합 서비스 - 간단한 버전
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceSimpleSlackService {
    
    /**
     * 팀 알림 발송 - 단일 InvocableMethod
     */
    @InvocableMethod(label='Send Team Notification' description='팀에 알림을 발송합니다')
    public static List<SlackNotificationResult> sendTeamNotification(List<SlackNotificationRequest> requests) {
        List<SlackNotificationResult> results = new List<SlackNotificationResult>();
        
        for(SlackNotificationRequest request : requests) {
            SlackNotificationResult result = new SlackNotificationResult();
            
            try {
                switch on request.notificationType {
                    when 'ORDER_UPDATE' {
                        result = handleOrderNotification(request);
                    }
                    when 'PAYMENT_ALERT' {
                        result = handlePaymentNotification(request);
                    }
                    when 'GENERAL' {
                        result = handleGeneralNotification(request);
                    }
                    when else {
                        result = handleGeneralNotification(request);
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
    
    // Order 알림 처리
    private static SlackNotificationResult handleOrderNotification(SlackNotificationRequest request) {
        SlackNotificationResult result = new SlackNotificationResult();
        
        try {
            // Salesforce Chatter를 활용한 내부 알림
            FeedItem feedItem = new FeedItem();
            feedItem.ParentId = request.recordId;
            feedItem.Body = '📋 주문 업데이트 알림\n\n' + 
                           (String.isNotBlank(request.message) ? request.message : '주문 상태가 업데이트되었습니다.');
            feedItem.Type = 'TextPost';
            
            insert feedItem;
            
            result.success = true;
            result.notificationId = feedItem.Id;
            result.message = '주문 알림이 성공적으로 발송되었습니다.';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '주문 알림 발송 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Payment 알림 처리
    private static SlackNotificationResult handlePaymentNotification(SlackNotificationRequest request) {
        SlackNotificationResult result = new SlackNotificationResult();
        
        try {
            // Chatter 알림
            FeedItem feedItem = new FeedItem();
            feedItem.ParentId = request.recordId;
            feedItem.Body = '💰 결제 상태 알림\n\n' + 
                           (String.isNotBlank(request.message) ? request.message : '결제 상태가 변경되었습니다.');
            feedItem.Type = 'TextPost';
            
            insert feedItem;
            
            result.success = true;
            result.notificationId = feedItem.Id;
            result.message = '결제 알림이 성공적으로 발송되었습니다.';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '결제 알림 발송 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // 일반 알림 처리
    private static SlackNotificationResult handleGeneralNotification(SlackNotificationRequest request) {
        SlackNotificationResult result = new SlackNotificationResult();
        
        try {
            // Chatter 알림
            FeedItem feedItem = new FeedItem();
            feedItem.ParentId = String.isNotBlank(request.recordId) ? request.recordId : UserInfo.getUserId();
            feedItem.Body = '📢 팀 알림\n\n' + 
                           (String.isNotBlank(request.message) ? request.message : '새로운 알림이 있습니다.');
            feedItem.Type = 'TextPost';
            
            insert feedItem;
            
            result.success = true;
            result.notificationId = feedItem.Id;
            result.message = '팀 알림이 성공적으로 발송되었습니다.';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = '팀 알림 발송 중 오류: ' + e.getMessage();
        }
        
        return result;
    }
    
    // Wrapper Classes
    public class SlackNotificationRequest {
        @InvocableVariable(label='Record ID')
        public String recordId;
        
        @InvocableVariable(label='Notification Type' required=true)
        public String notificationType; // ORDER_UPDATE, PAYMENT_ALERT, GENERAL
        
        @InvocableVariable(label='Message' required=true)
        public String message;
        
        @InvocableVariable(label='Priority')
        public String priority; // HIGH, MEDIUM, LOW
    }
    
    public class SlackNotificationResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public String notificationId;
        
        @InvocableVariable
        public String errorMessage;
        
        public SlackNotificationResult() {
            this.success = false;
        }
    }
    
    // 기존 호환성을 위한 클래스들
    public class SlackChannelRequest {
        @InvocableVariable
        public String orderId;
        @InvocableVariable
        public Boolean includeTeamMembers;
    }
    
    public class SlackChannelResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String channelName;
        @InvocableVariable
        public String channelId;
        @InvocableVariable
        public String errorMessage;
    }
    
    public class PaymentNotificationRequest {
        @InvocableVariable
        public String paymentId;
        @InvocableVariable
        public String notificationType;
    }
    
    public class PaymentNotificationResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
        @InvocableVariable
        public String errorMessage;
    }
}

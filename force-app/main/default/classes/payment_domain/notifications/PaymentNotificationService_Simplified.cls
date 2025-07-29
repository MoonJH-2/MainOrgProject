/**
 * Payment 알림 서비스 (간소화 버전)
 * Salesforce 채널 통합
 */
public with sharing class PaymentNotificationServiceSimplified {
    
    /**
     * Payment 알림 처리 (메인 메서드)
     */
    public static void processNotification(Payment_Notification__c notification) {
        try {
            System.debug('📧 Payment 알림 처리 시작: ' + notification.Id);
            
            // 1. Salesforce 채널 알림 (우선순위)
            Boolean salesforceSuccess = sendSalesforceChannelNotification(notification);
            
            // 2. 이메일 알림 (기본)
            Boolean emailSuccess = sendEmailNotification(notification);
            
            // 3. Chatter 포스트 (보조)
            Boolean chatterSuccess = createChatterPost(notification);
            
            System.debug('✅ 알림 처리 완료 - Salesforce: ' + salesforceSuccess + 
                        ', Email: ' + emailSuccess + ', Chatter: ' + chatterSuccess);
            
        } catch(Exception e) {
            System.debug('❌ Payment 알림 처리 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Salesforce 채널 알림 발송
     */
    public static Boolean sendSalesforceChannelNotification(Payment_Notification__c notification) {
        try {
            // Order 정보 조회
            List<Order> orders = [
                SELECT Id, OrderNumber, Name
                FROM Order 
                WHERE Id = :notification.Order__c 
                LIMIT 1
            ];
            
            if(orders.isEmpty()) {
                System.debug('❌ Order를 찾을 수 없습니다: ' + notification.Order__c);
                return false;
            }
            
            Order order = orders[0];
            
            // Salesforce 채널 찾기
            List<CollaborationGroup> channels = [
                SELECT Id, Name FROM CollaborationGroup 
                WHERE Name LIKE :('%' + order.OrderNumber + '%')
                LIMIT 1
            ];
            
            if(channels.isEmpty()) {
                System.debug('❌ Salesforce 채널을 찾을 수 없습니다: ' + order.OrderNumber);
                return false;
            }
            
            // 채널에 알림 메시지 발송
            String message = createChannelNotificationMessage(notification, order);
            
            SalesforceChannelService channelService = new SalesforceChannelService();
            Boolean success = channelService.sendChannelMessage(channels[0].Id, message);
            
            if(success) {
                System.debug('✅ Salesforce 채널 알림 발송 완료: ' + channels[0].Name);
            }
            
            return success;
            
        } catch(Exception e) {
            System.debug('❌ Salesforce 채널 알림 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 채널 알림 메시지 생성
     */
    private static String createChannelNotificationMessage(Payment_Notification__c notification, Order order) {
        String message = '💰 Payment 알림\n\n';
        message += '📋 Order: ' + order.OrderNumber + '\n';
        message += '💳 알림 유형: ' + notification.Notification_Type__c + '\n';
        message += '💵 금액: ₩' + String.valueOf(notification.Amount__c?.setScale(0).format()) + '\n';
        message += '📅 예정일: ' + (notification.Due_Date__c != null ? notification.Due_Date__c.format() : 'N/A') + '\n';
        message += '⚠️ 상태: ' + notification.Status__c + '\n\n';
        
        if(notification.Notification_Type__c == 'Overdue') {
            message += '🚨 연체 알림! 즉시 확인이 필요합니다.\n';
        } else if(notification.Notification_Type__c == 'Reminder') {
            message += '⏰ 납부 예정일이 다가오고 있습니다.\n';
        }
        
        message += '\n🔗 Order 확인: ' + System.URL.getOrgDomainUrl().toExternalForm() + 
                  '/lightning/r/Order/' + order.Id + '/view\n';
        message += '🕒 ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n\n';
        message += '#PaymentAlert #긴급확인필요';
        
        return message;
    }
    
    /**
     * 이메일 알림 발송
     */
    public static Boolean sendEmailNotification(Payment_Notification__c notification) {
        try {
            // 간소화된 이메일 발송
            String customerEmail = getCustomerEmail(notification);
            
            if(String.isBlank(customerEmail)) {
                System.debug('❌ 고객 이메일을 찾을 수 없습니다');
                return false;
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{customerEmail});
            email.setSubject('Payment 알림 - ' + notification.Notification_Type__c);
            email.setPlainTextBody('Payment 알림입니다. 자세한 내용은 Salesforce에서 확인하세요.');
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            System.debug('✅ 이메일 발송 완료: ' + customerEmail);
            return true;
            
        } catch(Exception e) {
            System.debug('❌ 이메일 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Chatter 포스트 생성
     */
    public static Boolean createChatterPost(Payment_Notification__c notification) {
        try {
            FeedItem post = new FeedItem();
            post.ParentId = notification.Order__c;
            post.Body = '💰 Payment 알림: ' + notification.Notification_Type__c + 
                       ' (금액: ₩' + String.valueOf(notification.Amount__c?.setScale(0).format()) + ')';
            post.Type = 'TextPost';
            
            insert post;
            
            System.debug('✅ Chatter 포스트 생성 완료');
            return true;
            
        } catch(Exception e) {
            System.debug('❌ Chatter 포스트 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 고객 이메일 조회
     */
    private static String getCustomerEmail(Payment_Notification__c notification) {
        try {
            List<Order> orders = [
                SELECT Id, Account.PersonEmail, Contact.Email
                FROM Order 
                WHERE Id = :notification.Order__c 
                LIMIT 1
            ];
            
            if(!orders.isEmpty()) {
                Order order = orders[0];
                if(String.isNotBlank(order.Account.PersonEmail)) {
                    return order.Account.PersonEmail;
                } else if(String.isNotBlank(order.Contact.Email)) {
                    return order.Contact.Email;
                }
            }
            
            return null;
            
        } catch(Exception e) {
            System.debug('❌ 고객 이메일 조회 오류: ' + e.getMessage());
            return null;
        }
    }
}

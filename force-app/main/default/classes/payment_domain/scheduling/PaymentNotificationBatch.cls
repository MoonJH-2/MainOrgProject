/**
 * @description 일일 납부 알림 배치 잡
 * @author JH Moon
 * @date 2025-07-15
 */
public class PaymentNotificationBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Integer successCount = 0;
    public Integer failureCount = 0;
    
    /**
     * 오늘 발송해야 할 알림 조회
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime todayStart = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        DateTime todayEnd = DateTime.newInstance(Date.today(), Time.newInstance(23, 59, 59, 999));
        
        String query = 'SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c, ' +
                      'PaymentStatus__r.Order__r.Account.Name, ' +
                      'PaymentStatus__r.Order__r.Account.Id, ' +
                      'PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.Installment_Number__c, ' +
                      'PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c, ' +
                      'NotificationType__c, NotificationChannel__c, NotificationStatus__c, ' +
                      'ScheduledDateTime__c, RecipientEmail__c ' +
                      'FROM Payment_Notification__c ' +
                      'WHERE NotificationStatus__c = \'Pending\' ' +
                      'AND ScheduledDateTime__c >= :todayStart ' +
                      'AND ScheduledDateTime__c <= :todayEnd ' +
                      'ORDER BY ScheduledDateTime__c ASC';
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * 알림 발송 처리
     */
    public void execute(Database.BatchableContext BC, List<Payment_Notification__c> notifications) {
        for (Payment_Notification__c notification : notifications) {
            try {
                // PaymentStatus가 이미 완납된 경우 알림 취소
                if (notification.PaymentStatus__r.Status__c == '완납') {
                    notification.NotificationStatus__c = 'Cancelled';
                    successCount++;
                    continue;
                }
                
                // 알림 발송 실행
                Boolean sendResult = sendNotification(notification);
                
                if (sendResult) {
                    notification.NotificationStatus__c = 'Sent';
                    notification.SentDateTime__c = DateTime.now();
                    successCount++;
                } else {
                    notification.NotificationStatus__c = 'Failed';
                    notification.ErrorMessage__c = '알림 발송에 실패했습니다.';
                    failureCount++;
                }
                
            } catch (Exception e) {
                notification.NotificationStatus__c = 'Failed';
                notification.ErrorMessage__c = e.getMessage();
                failureCount++;
                System.debug('알림 발송 오류: ' + e.getMessage());
            }
        }
        
        // 알림 상태 업데이트
        if (!notifications.isEmpty()) {
            update notifications;
        }
    }
    
    /**
     * 배치 완료 후 처리
     */
    public void finish(Database.BatchableContext BC) {
        System.debug('알림 배치 완료 - 성공: ' + successCount + '건, 실패: ' + failureCount + '건');
        
        // 관리자에게 배치 실행 결과 알림 (선택사항)
        if (failureCount > 0) {
            sendBatchResultNotification(successCount, failureCount);
        }
    }
    
    /**
     * 채널별 알림 발송
     */
    private Boolean sendNotification(Payment_Notification__c notification) {
        try {
            switch on notification.NotificationChannel__c {
                when 'Salesforce' {
                    return PaymentNotificationService.sendSalesforceNotification(notification);
                }
                when 'SalesforceChannel' {
                    return PaymentNotificationService.sendSalesforceChannelNotification(notification);
                }
                when 'Email' {
                    return PaymentNotificationService.sendEmailNotification(notification);
                }
                when 'Slack' {
                    return PaymentNotificationService.sendSlackNotification(notification);
                }
                when else {
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug('알림 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 배치 실행 결과 알림
     */
    private void sendBatchResultNotification(Integer success, Integer failure) {
        // 관리자에게 배치 실행 결과 이메일 발송
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('[배치 알림] 납부 알림 배치 실행 결과');
        
        String body = '납부 알림 배치가 완료되었습니다.\n\n';
        body += '성공: ' + success + '건\n';
        body += '실패: ' + failure + '건\n\n';
        body += '실패한 알림은 Payment_Notification__c 객체에서 확인하실 수 있습니다.';
        
        email.setPlainTextBody(body);
        // 실제 구현 시 관리자 이메일 설정 필요
        email.setToAddresses(new String[]{ 'eetd0000@gmail.com' });
        
        try {
            // Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
        } catch (Exception e) {
            System.debug('배치 결과 알림 발송 오류: ' + e.getMessage());
        }
    }
}

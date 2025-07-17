/**
 * @description 납부 알림 스케줄링 서비스
 * @author JH Moon
 * @date 2025-07-15
 */
public with sharing class PaymentNotificationScheduler {
    
    /**
     * PaymentStatus 생성/수정 시 알림 스케줄링
     */
    public static void scheduleNotifications(List<PaymentStatus__c> paymentStatuses) {
        List<Payment_Notification__c> notificationsToInsert = new List<Payment_Notification__c>();
        
        for (PaymentStatus__c ps : paymentStatuses) {
            // 이미 완납된 건은 알림 생성하지 않음
            if (ps.Status__c == '완납') {
                continue;
            }
            
            // 예정 알림 생성 (DueDate - 3일)
            if (ps.DueDate__c != null && ps.DueDate__c >= Date.today().addDays(3)) {
                Payment_Notification__c reminderNotification = createNotification(
                    ps.Id, 
                    '예정 알림', 
                    ps.DueDate__c.addDays(-3)
                );
                notificationsToInsert.add(reminderNotification);
            }
            
            // 연체 알림 생성 (DueDate + 1일)
            if (ps.DueDate__c != null) {
                Payment_Notification__c overdueNotification = createNotification(
                    ps.Id, 
                    '연체 알림', 
                    ps.DueDate__c.addDays(1)
                );
                notificationsToInsert.add(overdueNotification);
            }
        }
        
        if (!notificationsToInsert.isEmpty()) {
            try {
                insert notificationsToInsert;
                System.debug('알림 스케줄링 완료: ' + notificationsToInsert.size() + '건');
            } catch (Exception e) {
                System.debug('알림 스케줄링 오류: ' + e.getMessage());
            }
        }
    }
    
    /**
     * PaymentStatus 완납 시 예정된 알림 취소
     */
    public static void cancelNotifications(List<PaymentStatus__c> completedPayments) {
        Set<Id> paymentStatusIds = new Set<Id>();
        
        for (PaymentStatus__c ps : completedPayments) {
            if (ps.Status__c == '완납') {
                paymentStatusIds.add(ps.Id);
            }
        }
        
        if (!paymentStatusIds.isEmpty()) {
            List<Payment_Notification__c> notificationsToCancel = [
                SELECT Id, NotificationStatus__c 
                FROM Payment_Notification__c 
                WHERE PaymentStatus__c IN :paymentStatusIds 
                AND NotificationStatus__c = 'Pending'
            ];
            
            for (Payment_Notification__c notification : notificationsToCancel) {
                notification.NotificationStatus__c = 'Cancelled';
            }
            
            if (!notificationsToCancel.isEmpty()) {
                update notificationsToCancel;
                System.debug('알림 취소 완료: ' + notificationsToCancel.size() + '건');
            }
        }
    }
    
    /**
     * 알림 객체 생성 헬퍼 메서드
     */
    private static Payment_Notification__c createNotification(
        Id paymentStatusId, 
        String notificationType, 
        Date scheduledDate
    ) {
        Payment_Notification__c notification = new Payment_Notification__c();
        notification.PaymentStatus__c = paymentStatusId;
        notification.NotificationType__c = notificationType;
        notification.NotificationChannel__c = 'Salesforce'; // 기본 채널
        notification.NotificationStatus__c = 'Pending';
        notification.ScheduledDateTime__c = DateTime.newInstance(
            scheduledDate.year(), 
            scheduledDate.month(), 
            scheduledDate.day(), 
            9, 0, 0  // 오전 9시 발송
        );
        
        return notification;
    }
}

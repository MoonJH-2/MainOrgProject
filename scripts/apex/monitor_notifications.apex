// 스마트 알림 시스템 모니터링

// 1. 전체 알림 통계
List<AggregateResult> statusStats = [
    SELECT NotificationStatus__c status, COUNT(Id) cnt
    FROM Payment_Notification__c 
    WHERE CreatedDate = TODAY
    GROUP BY NotificationStatus__c
];

System.debug('===== 오늘 알림 통계 =====');
for (AggregateResult ar : statusStats) {
    System.debug(ar.get('status') + ': ' + ar.get('cnt') + '건');
}

// 2. 채널별 통계
List<AggregateResult> channelStats = [
    SELECT NotificationChannel__c channel, COUNT(Id) cnt
    FROM Payment_Notification__c 
    WHERE CreatedDate = TODAY
    AND NotificationStatus__c = 'Sent'
    GROUP BY NotificationChannel__c
];

System.debug('===== 채널별 발송 통계 =====');
for (AggregateResult ar : channelStats) {
    System.debug(ar.get('channel') + ': ' + ar.get('cnt') + '건');
}

// 3. 최근 알림 이력
List<Payment_Notification__c> recentNotifications = [
    SELECT Id, PaymentStatus__r.Order__r.Account.Name,
           PaymentStatus__r.Order__r.OrderNumber,
           PaymentStatus__r.InstallmentNumber__c,
           NotificationType__c, NotificationChannel__c,
           NotificationStatus__c, ScheduledDateTime__c,
           SentDateTime__c, ErrorMessage__c
    FROM Payment_Notification__c 
    WHERE CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 10
];

System.debug('===== 최근 알림 이력 (최대 10건) =====');
for (Payment_Notification__c notification : recentNotifications) {
    String status = notification.NotificationStatus__c;
    String customer = notification.PaymentStatus__r.Order__r.Account.Name;
    String orderNum = notification.PaymentStatus__r.Order__r.OrderNumber;
    String installment = String.valueOf(notification.PaymentStatus__r.InstallmentNumber__c);
    String type = notification.NotificationType__c;
    String channel = notification.NotificationChannel__c;
    
    String logMsg = customer + ' (' + orderNum + ') ' + installment + '차 ' + 
                   type + ' [' + channel + '] - ' + status;
    
    if (notification.SentDateTime__c != null) {
        logMsg += ' (발송: ' + notification.SentDateTime__c.format() + ')';
    }
    
    if (String.isNotBlank(notification.ErrorMessage__c)) {
        logMsg += ' (오류: ' + notification.ErrorMessage__c + ')';
    }
    
    System.debug(logMsg);
}

// 4. 실패한 알림 확인
List<Payment_Notification__c> failedNotifications = [
    SELECT Id, ErrorMessage__c, PaymentStatus__r.Order__r.Account.Name
    FROM Payment_Notification__c 
    WHERE NotificationStatus__c = 'Failed'
    AND CreatedDate >= YESTERDAY
];

if (!failedNotifications.isEmpty()) {
    System.debug('===== 실패한 알림 (' + failedNotifications.size() + '건) =====');
    for (Payment_Notification__c failed : failedNotifications) {
        System.debug('고객: ' + failed.PaymentStatus__r.Order__r.Account.Name + 
                    ' | 오류: ' + failed.ErrorMessage__c);
    }
} else {
    System.debug('===== 실패한 알림 없음 =====');
}

// 5. 예정된 알림 확인
List<Payment_Notification__c> pendingNotifications = [
    SELECT Id, PaymentStatus__r.Order__r.Account.Name,
           NotificationType__c, ScheduledDateTime__c
    FROM Payment_Notification__c 
    WHERE NotificationStatus__c = 'Pending'
    AND ScheduledDateTime__c >= NOW
    ORDER BY ScheduledDateTime__c ASC
    LIMIT 5
];

if (!pendingNotifications.isEmpty()) {
    System.debug('===== 예정된 알림 (다음 5건) =====');
    for (Payment_Notification__c pending : pendingNotifications) {
        System.debug(pending.PaymentStatus__r.Order__r.Account.Name + ' - ' +
                    pending.NotificationType__c + ' (' + 
                    pending.ScheduledDateTime__c.format() + ')');
    }
} else {
    System.debug('===== 예정된 알림 없음 =====');
}

System.debug('모니터링 완료');

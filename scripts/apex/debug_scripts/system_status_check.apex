// Scheduled Jobs 상태 확인 스크립트

System.debug('=== 스케줄된 작업 상태 확인 ===');

// 현재 활성화된 스케줄된 작업들 조회
List<CronTrigger> scheduledJobs = [
    SELECT Id, CronJobDetail.Name, CronJobDetail.JobType, 
           State, NextFireTime, PreviousFireTime, CronExpression
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%Payment%'
];

if (scheduledJobs.isEmpty()) {
    System.debug('⚠️ Payment 관련 스케줄된 작업이 없습니다.');
} else {
    for (CronTrigger job : scheduledJobs) {
        System.debug('📋 스케줄된 작업:');
        System.debug('  - 이름: ' + job.CronJobDetail.Name);
        System.debug('  - 상태: ' + job.State);
        System.debug('  - 다음 실행: ' + job.NextFireTime);
        System.debug('  - 이전 실행: ' + job.PreviousFireTime);
        System.debug('  - Cron 표현식: ' + job.CronExpression);
        System.debug('---');
    }
}

System.debug('=== 배치 작업 히스토리 확인 ===');

// 최근 배치 작업 실행 히스토리 조회
List<AsyncApexJob> batchJobs = [
    SELECT Id, ApexClass.Name, Status, JobItemsProcessed, 
           TotalJobItems, NumberOfErrors, CreatedDate, CompletedDate
    FROM AsyncApexJob 
    WHERE ApexClass.Name = 'PaymentNotificationBatch'
    ORDER BY CreatedDate DESC
    LIMIT 10
];

if (batchJobs.isEmpty()) {
    System.debug('⚠️ PaymentNotificationBatch 실행 히스토리가 없습니다.');
} else {
    for (AsyncApexJob job : batchJobs) {
        System.debug('🔄 배치 작업:');
        System.debug('  - ID: ' + job.Id);
        System.debug('  - 상태: ' + job.Status);
        System.debug('  - 처리된 항목: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
        System.debug('  - 오류 수: ' + job.NumberOfErrors);
        System.debug('  - 생성일: ' + job.CreatedDate);
        System.debug('  - 완료일: ' + job.CompletedDate);
        System.debug('---');
    }
}

System.debug('=== 최근 알림 현황 ===');

// 최근 생성된 알림들 조회
List<Payment_Notification__c> recentNotifications = [
    SELECT Id, NotificationType__c, NotificationChannel__c, 
           NotificationStatus__c, ScheduledDateTime__c, SentDateTime__c,
           PaymentStatus__r.Order__r.OrderNumber, ErrorMessage__c
    FROM Payment_Notification__c 
    ORDER BY CreatedDate DESC
    LIMIT 20
];

if (recentNotifications.isEmpty()) {
    System.debug('⚠️ 생성된 알림이 없습니다.');
} else {
    for (Payment_Notification__c notification : recentNotifications) {
        System.debug('📧 알림:');
        System.debug('  - ID: ' + notification.Id);
        System.debug('  - 유형: ' + notification.NotificationType__c);
        System.debug('  - 채널: ' + notification.NotificationChannel__c);
        System.debug('  - 상태: ' + notification.NotificationStatus__c);
        System.debug('  - 예정시간: ' + notification.ScheduledDateTime__c);
        System.debug('  - 발송시간: ' + notification.SentDateTime__c);
        System.debug('  - 주문번호: ' + notification.PaymentStatus__r.Order__r.OrderNumber);
        if (String.isNotBlank(notification.ErrorMessage__c)) {
            System.debug('  - 오류: ' + notification.ErrorMessage__c);
        }
        System.debug('---');
    }
}

System.debug('=== 상태 확인 완료 ===');

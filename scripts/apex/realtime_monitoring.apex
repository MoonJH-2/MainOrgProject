// 실시간 모니터링 스크립트 - 정기적으로 실행하여 시스템 상태 확인

System.debug('=== 알림 시스템 실시간 모니터링 ===');

// 1. 오늘 생성된 알림 통계
Date today = Date.today();
List<AggregateResult> todayStats = [
    SELECT NotificationType__c, NotificationChannel__c, NotificationStatus__c,
           COUNT(Id) cnt
    FROM Payment_Notification__c 
    WHERE CreatedDate = TODAY
    GROUP BY NotificationType__c, NotificationChannel__c, NotificationStatus__c
];

System.debug('📊 오늘 알림 통계:');
for (AggregateResult stat : todayStats) {
    System.debug(String.format('  {0} | {1} | {2}: {3}건', 
        new List<String>{
            String.valueOf(stat.get('NotificationType__c')),
            String.valueOf(stat.get('NotificationChannel__c')),
            String.valueOf(stat.get('NotificationStatus__c')),
            String.valueOf(stat.get('cnt'))
        }));
}

// 2. 대기 중인 알림 수
Integer pendingCount = [
    SELECT COUNT() 
    FROM Payment_Notification__c 
    WHERE NotificationStatus__c = 'Pending'
    AND ScheduledDateTime__c <= :DateTime.now()
];
System.debug('⏳ 처리 대기 중인 알림: ' + pendingCount + '건');

// 3. 실패한 알림 수
Integer failedCount = [
    SELECT COUNT() 
    FROM Payment_Notification__c 
    WHERE NotificationStatus__c = 'Failed'
    AND CreatedDate = TODAY
];
System.debug('❌ 오늘 실패한 알림: ' + failedCount + '건');

// 4. 성공률 계산
Integer totalSent = [
    SELECT COUNT() 
    FROM Payment_Notification__c 
    WHERE SentDateTime__c != null
    AND CreatedDate = TODAY
];

Integer successfulSent = [
    SELECT COUNT() 
    FROM Payment_Notification__c 
    WHERE NotificationStatus__c = 'Sent'
    AND CreatedDate = TODAY
];

if (totalSent > 0) {
    Decimal successRate = (Decimal.valueOf(successfulSent) / Decimal.valueOf(totalSent)) * 100;
    System.debug('✅ 오늘 성공률: ' + successRate.setScale(1) + '%');
} else {
    System.debug('📊 오늘 발송된 알림이 없습니다.');
}

// 5. 다음 스케줄된 작업 확인
List<CronTrigger> nextJobs = [
    SELECT CronJobDetail.Name, NextFireTime
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%Payment%'
    AND State = 'WAITING'
    ORDER BY NextFireTime ASC
    LIMIT 3
];

System.debug('⏰ 다음 예정된 작업:');
for (CronTrigger job : nextJobs) {
    System.debug('  ' + job.CronJobDetail.Name + ': ' + job.NextFireTime);
}

System.debug('=== 모니터링 완료 ===');

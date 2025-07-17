// 스마트 알림 시스템 활성화 스크립트

// 1. 기존 스케줄 확인 및 정리
List<CronTrigger> existingJobs = [
    SELECT Id, CronJobDetail.Name 
    FROM CronTrigger 
    WHERE CronJobDetail.Name LIKE '%Payment%Notification%'
    AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
];

System.debug('기존 스케줄 수: ' + existingJobs.size());
for (CronTrigger job : existingJobs) {
    System.debug('기존 스케줄: ' + job.CronJobDetail.Name);
    System.abortJob(job.Id);
}

// 2. 새로운 일일 스케줄 등록 (매일 오전 9시)
String jobId = PaymentNotificationSchedulable.scheduleDaily();
System.debug('새 스케줄 등록 완료: ' + jobId);

// 3. 스케줄 등록 확인
List<CronTrigger> newJobs = [
    SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime, State
    FROM CronTrigger 
    WHERE Id = :jobId
];

if (!newJobs.isEmpty()) {
    CronTrigger job = newJobs[0];
    System.debug('===== 스케줄 등록 성공 =====');
    System.debug('Job ID: ' + job.Id);
    System.debug('Job Name: ' + job.CronJobDetail.Name);
    System.debug('Cron Expression: ' + job.CronExpression);
    System.debug('Next Fire Time: ' + job.NextFireTime);
    System.debug('State: ' + job.State);
    System.debug('========================');
} else {
    System.debug('스케줄 등록 실패');
}

System.debug('스마트 알림 시스템 활성화 완료!');

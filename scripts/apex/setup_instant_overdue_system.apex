// 즉시 연체 처리 시스템 설정 및 테스트

// 1. 즉시 연체 처리 시스템 설정
PaymentOverdueCheckScheduler.setupComprehensiveScheduling();

// 2. 현재 스케줄된 작업 확인
List<CronTrigger> scheduledJobs = [
    SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime, State
    FROM CronTrigger 
    WHERE CronJobDetail.Name IN ('PaymentOverdueCheck', 'PaymentMidnightOverdueCheck')
    AND State IN ('WAITING', 'ACQUIRED')
];

System.debug('=== 스케줄된 작업 목록 ===');
for (CronTrigger job : scheduledJobs) {
    System.debug('작업명: ' + job.CronJobDetail.Name);
    System.debug('크론 표현식: ' + job.CronExpression);
    System.debug('다음 실행 시간: ' + job.NextFireTime);
    System.debug('상태: ' + job.State);
    System.debug('---');
}

// 3. 테스트용 연체 상황 시뮬레이션
Date yesterday = Date.today().addDays(-1);

// 어제가 기일이었지만 아직 미납인 PaymentStatus 조회
List<PaymentStatus__c> testOverduePayments = [
    SELECT Id, Order__r.OrderNumber, InstallmentNumber__c, Status__c, DueDate__c
    FROM PaymentStatus__c 
    WHERE DueDate__c = :yesterday
    AND Status__c = '미납'
    LIMIT 5
];

System.debug('=== 테스트 대상 연체 건들 ===');
for (PaymentStatus__c ps : testOverduePayments) {
    System.debug('주문번호: ' + ps.Order__r.OrderNumber + ', 차수: ' + ps.InstallmentNumber__c);
    System.debug('기일: ' + ps.DueDate__c + ', 상태: ' + ps.Status__c);
}

// 4. 즉시 연체 체크 테스트
if (!testOverduePayments.isEmpty()) {
    System.debug('=== 즉시 연체 체크 실행 ===');
    PaymentOverdueService.dailyOverdueCheck();
    System.debug('즉시 연체 체크가 완료되었습니다.');
}

System.debug('=== 설정 완료 ===');
System.debug('연체 처리 시스템이 다음과 같이 동작합니다:');
System.debug('1. 실시간: PaymentStatus 생성/수정 시 즉시 연체 체크 (트리거)');
System.debug('2. 자정 00:00: 연체 전환 즉시 처리');
System.debug('3. 오전 09:00: 놓친 연체 건들 보완 처리');

// 주문 00000119의 연체 상황 및 Task 생성 확인

// 1. 해당 주문의 PaymentStatus 확인
List<PaymentStatus__c> paymentStatuses = [
    SELECT Id, Order__c, Order__r.OrderNumber, Amount__c, DueDate__c, 
           InstallmentNumber__c, Status__c, PaidDate__c
    FROM PaymentStatus__c 
    WHERE Order__r.OrderNumber = '00000119'
    ORDER BY InstallmentNumber__c ASC
];

System.debug('=== 주문 00000119 PaymentStatus 목록 ===');
for (PaymentStatus__c ps : paymentStatuses) {
    System.debug('차수: ' + ps.InstallmentNumber__c);
    System.debug('금액: ' + ps.Amount__c);
    System.debug('기일: ' + ps.DueDate__c);
    System.debug('상태: ' + ps.Status__c);
    System.debug('연체 여부: ' + (ps.DueDate__c < Date.today() && ps.Status__c == '미납' ? 'YES' : 'NO'));
    System.debug('---');
}

// 2. 해당 주문과 관련된 Task 확인
List<Task> relatedTasks = [
    SELECT Id, Subject, Description, Status, Priority, CreatedDate, ActivityDate, Type
    FROM Task 
    WHERE WhatId IN (SELECT Order__c FROM PaymentStatus__c WHERE Order__r.OrderNumber = '00000119')
    OR Subject LIKE '%00000119%'
    ORDER BY CreatedDate DESC
];

System.debug('=== 주문 00000119 관련 Task 목록 ===');
for (Task t : relatedTasks) {
    System.debug('제목: ' + t.Subject);
    System.debug('생성일: ' + t.CreatedDate);
    System.debug('상태: ' + t.Status);
    System.debug('우선순위: ' + t.Priority);
    System.debug('유형: ' + t.Type);
    System.debug('---');
}

// 3. 오늘 생성된 연체 관련 Task 전체 확인
List<Task> todayOverdueTasks = [
    SELECT Subject, CreatedDate FROM Task 
    WHERE Subject LIKE '연체 알림%' 
    AND CreatedDate = TODAY
];

System.debug('=== 오늘 생성된 연체 알림 Task ===');
for (Task t : todayOverdueTasks) {
    System.debug('제목: ' + t.Subject + ', 생성시간: ' + t.CreatedDate);
}

// 4. 현재 스케줄된 작업 확인
List<CronTrigger> scheduledJobs = [
    SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime, State
    FROM CronTrigger 
    WHERE CronJobDetail.Name IN ('PaymentOverdueCheck', 'PaymentMidnightOverdueCheck')
    AND State IN ('WAITING', 'ACQUIRED')
];

System.debug('=== 현재 스케줄된 연체 처리 작업 ===');
for (CronTrigger job : scheduledJobs) {
    System.debug('작업명: ' + job.CronJobDetail.Name);
    System.debug('다음 실행: ' + job.NextFireTime);
    System.debug('상태: ' + job.State);
    System.debug('---');
}

System.debug('=== 분석 완료 ===');

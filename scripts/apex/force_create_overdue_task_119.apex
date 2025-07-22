// 주문 00000119의 연체 PaymentStatus에 대해 강제로 Task 생성

// 1. 해당 주문의 연체된 PaymentStatus ID 찾기
List<PaymentStatus__c> overduePayments = [
    SELECT Id, Order__c, Order__r.OrderNumber, Amount__c, DueDate__c, 
           InstallmentNumber__c, Status__c
    FROM PaymentStatus__c 
    WHERE Order__r.OrderNumber = '00000119'
    AND DueDate__c < :Date.today()
    AND Status__c = '미납'
];

System.debug('=== 주문 00000119 연체 건들 ===');
List<Id> overdueIds = new List<Id>();
for (PaymentStatus__c ps : overduePayments) {
    System.debug('차수: ' + ps.InstallmentNumber__c + ', 기일: ' + ps.DueDate__c + ', 상태: ' + ps.Status__c);
    overdueIds.add(ps.Id);
}

// 2. 직접 연체 Task 생성 실행
if (!overdueIds.isEmpty()) {
    System.debug('=== 연체 Task 생성 실행 ===');
    try {
        PaymentStatusTimelineController.checkOverdueAndCreateTasks(overdueIds);
        System.debug('연체 Task 생성이 완료되었습니다.');
        
        // 생성된 Task 확인
        List<Task> newTasks = [
            SELECT Subject, CreatedDate, Status, Priority
            FROM Task 
            WHERE Subject LIKE '%00000119%'
            AND CreatedDate = TODAY
            ORDER BY CreatedDate DESC
        ];
        
        System.debug('=== 새로 생성된 Task 목록 ===');
        for (Task t : newTasks) {
            System.debug('제목: ' + t.Subject);
            System.debug('생성시간: ' + t.CreatedDate);
            System.debug('상태: ' + t.Status);
            System.debug('우선순위: ' + t.Priority);
            System.debug('---');
        }
        
    } catch (Exception e) {
        System.debug('연체 Task 생성 중 오류: ' + e.getMessage());
        System.debug('스택 트레이스: ' + e.getStackTraceString());
    }
} else {
    System.debug('연체된 PaymentStatus가 없습니다.');
}

// 3. 스케줄러 재설정 (필요시)
System.debug('=== 스케줄러 재설정 ===');
try {
    PaymentOverdueCheckScheduler.setupComprehensiveScheduling();
    System.debug('스케줄러가 재설정되었습니다.');
} catch (Exception e) {
    System.debug('스케줄러 설정 오류: ' + e.getMessage());
}

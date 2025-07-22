// 상세한 연체 처리 로직 디버깅

Date today = Date.today();
System.debug('=== 오늘 날짜: ' + today + ' ===');

// 1. 주문 00000119의 모든 PaymentStatus 상세 조회
List<PaymentStatus__c> allPayments = [
    SELECT Id, Order__c, Order__r.OrderNumber, Order__r.Account.Name,
           Amount__c, DueDate__c, InstallmentNumber__c, Status__c, PaidDate__c
    FROM PaymentStatus__c 
    WHERE Order__r.OrderNumber = '00000119'
    ORDER BY InstallmentNumber__c ASC
];

System.debug('=== 주문 00000119 전체 PaymentStatus ===');
for (PaymentStatus__c ps : allPayments) {
    System.debug('ID: ' + ps.Id);
    System.debug('차수: ' + ps.InstallmentNumber__c);
    System.debug('기일: ' + ps.DueDate__c);
    System.debug('상태: ' + ps.Status__c);
    System.debug('연체 조건 체크: DueDate(' + ps.DueDate__c + ') < Today(' + today + ') = ' + (ps.DueDate__c < today));
    System.debug('미납 조건 체크: Status(' + ps.Status__c + ') == 미납 = ' + (ps.Status__c == '미납'));
    System.debug('연체 여부: ' + (ps.DueDate__c != null && ps.DueDate__c < today && ps.Status__c == '미납'));
    System.debug('-----');
}

// 2. 연체 조건에 맞는 PaymentStatus 필터링
List<PaymentStatus__c> overduePayments = new List<PaymentStatus__c>();
List<Id> overdueIds = new List<Id>();

for (PaymentStatus__c ps : allPayments) {
    if (ps.DueDate__c != null && ps.DueDate__c < today && ps.Status__c == '미납') {
        overduePayments.add(ps);
        overdueIds.add(ps.Id);
    }
}

System.debug('=== 연체 조건 만족 PaymentStatus ===');
System.debug('연체 건수: ' + overduePayments.size());
for (PaymentStatus__c ps : overduePayments) {
    System.debug('연체 ID: ' + ps.Id + ', 차수: ' + ps.InstallmentNumber__c);
}

// 3. 기존 Task 확인
List<Task> existingTasks = [
    SELECT Subject, CreatedDate FROM Task 
    WHERE Subject LIKE '연체 알림 - 00000119%'
    ORDER BY CreatedDate DESC
];

System.debug('=== 기존 연체 알림 Task ===');
for (Task t : existingTasks) {
    System.debug('제목: ' + t.Subject + ', 생성일: ' + t.CreatedDate);
}

// 4. 오늘 생성될 예상 Subject 확인
Set<String> expectedSubjects = new Set<String>();
for (PaymentStatus__c ps : overduePayments) {
    String subject = '연체 알림 - ' + ps.Order__r.OrderNumber + ' ' + ps.InstallmentNumber__c + '차';
    expectedSubjects.add(subject);
    System.debug('예상 Subject: ' + subject);
}

// 5. 중복 체크
List<Task> todayTasks = [
    SELECT Subject FROM Task 
    WHERE Subject IN :expectedSubjects
    AND CreatedDate = TODAY
];

System.debug('=== 오늘 생성된 중복 Task ===');
for (Task t : todayTasks) {
    System.debug('중복 Subject: ' + t.Subject);
}

// 6. 직접 Task 생성 테스트
if (!overdueIds.isEmpty()) {
    System.debug('=== 연체 Task 생성 실행 ===');
    try {
        PaymentStatusTimelineController.checkOverdueAndCreateTasks(overdueIds);
        System.debug('SUCCESS: 연체 Task 생성 메서드 실행 완료');
    } catch (Exception e) {
        System.debug('ERROR: ' + e.getMessage());
        System.debug('STACK: ' + e.getStackTraceString());
    }
} else {
    System.debug('WARNING: 연체 조건을 만족하는 PaymentStatus가 없습니다.');
}

// 7. 생성 후 결과 확인
List<Task> newTasks = [
    SELECT Subject, CreatedDate, Status, Priority, Description
    FROM Task 
    WHERE Subject LIKE '연체 알림 - 00000119%'
    AND CreatedDate = TODAY
    ORDER BY CreatedDate DESC
];

System.debug('=== 생성된 새 Task 확인 ===');
if (newTasks.isEmpty()) {
    System.debug('WARNING: 새로운 연체 Task가 생성되지 않았습니다.');
} else {
    for (Task t : newTasks) {
        System.debug('새 Task: ' + t.Subject + ', 생성시간: ' + t.CreatedDate);
    }
}

System.debug('=== 디버깅 완료 ===');

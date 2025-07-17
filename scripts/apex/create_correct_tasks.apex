// Order 00000115에 직접 연체 알림 Task 생성
System.debug('=== Order 00000115에 연체 알림 Task 생성 ===');

// 1. 정확한 Order 00000115 조회
List<Order> orders = [SELECT Id, OrderNumber FROM Order WHERE OrderNumber = '00000115' LIMIT 1];

if (!orders.isEmpty()) {
    Id correctOrderId = orders[0].Id;
    System.debug('정확한 Order ID: ' + correctOrderId);
    
    // 2. 해당 Order의 연체된 PaymentStatus 조회
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
               Order__r.Account.Name
        FROM PaymentStatus__c 
        WHERE Order__c = :correctOrderId
        AND Status__c = '미납' 
        AND DueDate__c < TODAY
        ORDER BY InstallmentNumber__c ASC
        LIMIT 3
    ];
    
    System.debug('해당 Order의 연체 납부 건수: ' + overduePayments.size());
    
    if (!overduePayments.isEmpty()) {
        List<Task> tasksToCreate = new List<Task>();
        
        for (PaymentStatus__c ps : overduePayments) {
            Task overdueTask = new Task();
            overdueTask.WhatId = correctOrderId; // 정확한 Order ID 사용
            overdueTask.Subject = '연체 알림 - ' + ps.Order__r.Account.Name + ' ' + ps.InstallmentNumber__c + '차';
            overdueTask.Description = '고객님의 납부가 연체되었습니다. 연체 관리를 진행해주세요.\n\n' +
                                     '주문번호: 00000115\n' +
                                     '납부 회차: ' + ps.InstallmentNumber__c + '차\n' +
                                     '납부 금액: ₩' + String.valueOf(ps.Amount__c) + '\n' +
                                     '연체일: ' + ps.DueDate__c.format() + '\n' +
                                     '연체 기간: ' + (Date.today().daysBetween(ps.DueDate__c)) + '일';
            overdueTask.Priority = 'High';
            overdueTask.Status = 'Not Started';
            overdueTask.ActivityDate = Date.today().addDays(1);
            
            tasksToCreate.add(overdueTask);
            System.debug('Task 준비: ' + ps.InstallmentNumber__c + '차 (Order ID: ' + correctOrderId + ')');
        }
        
        // 3. Task 일괄 생성
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
            System.debug('생성된 Task 수: ' + tasksToCreate.size());
            
            for (Task t : tasksToCreate) {
                System.debug('생성 완료: ' + t.Id + ' (WhatId: ' + t.WhatId + ')');
            }
        }
        
        // 4. 검증: 해당 Order의 Task 확인
        List<Task> verifyTasks = [
            SELECT Id, Subject, Status, Priority, WhatId
            FROM Task 
            WHERE WhatId = :correctOrderId
            ORDER BY CreatedDate DESC
        ];
        
        System.debug('Order 00000115에 연결된 총 Task 수: ' + verifyTasks.size());
        for (Task t : verifyTasks) {
            System.debug('- ' + t.Subject + ' (상태: ' + t.Status + ')');
        }
        
    } else {
        System.debug('해당 Order에 연체된 납부가 없습니다.');
    }
    
} else {
    System.debug('Order 00000115를 찾을 수 없습니다.');
}

System.debug('=== Task 생성 완료 ===');

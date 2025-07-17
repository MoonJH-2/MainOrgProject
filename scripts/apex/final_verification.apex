// 최종 결과 확인
System.debug('=== 최종 결과 확인 ===');

// Order 00000115 확인
List<Order> orders = [SELECT Id, OrderNumber FROM Order WHERE OrderNumber = '00000115' LIMIT 1];

if (!orders.isEmpty()) {
    Id orderId = orders[0].Id;
    System.debug('Order 00000115 ID: ' + orderId);
    
    // 해당 Order에 연결된 Task 확인
    List<Task> orderTasks = [
        SELECT Id, Subject, Status, Priority, ActivityDate, Description, CreatedDate
        FROM Task 
        WHERE WhatId = :orderId
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('Order 00000115에 연결된 Task 수: ' + orderTasks.size());
    
    if (orderTasks.size() > 0) {
        System.debug('=== Task 목록 ===');
        for (Task t : orderTasks) {
            System.debug('Subject: ' + t.Subject);
            System.debug('Status: ' + t.Status + ', Priority: ' + t.Priority);
            System.debug('ActivityDate: ' + t.ActivityDate);
            System.debug('CreatedDate: ' + t.CreatedDate);
            System.debug('---');
        }
        
        System.debug('✅ 성공! Order 페이지 Activity Timeline에서 이 Task들을 확인할 수 있습니다.');
    } else {
        System.debug('❌ 아직 Task가 연결되지 않았습니다.');
    }
} else {
    System.debug('Order를 찾을 수 없습니다.');
}

// 간단한 결과 확인
System.debug('=== 간단한 결과 확인 ===');

// Order 00000115의 Task만 확인
List<Task> tasks = [
    SELECT Id, Subject, Status, Priority, WhatId, CreatedDate
    FROM Task 
    WHERE Subject LIKE '%연체 알림%'
    AND CreatedDate = TODAY
    ORDER BY CreatedDate DESC
];

System.debug('오늘 생성된 연체 알림 Task 수: ' + tasks.size());

for (Task t : tasks) {
    System.debug('Task: ' + t.Subject + ' (ID: ' + t.Id + ')');
    System.debug('     WhatId: ' + t.WhatId + ', 상태: ' + t.Status);
}

// Order 확인
List<Order> orders = [SELECT Id, OrderNumber FROM Order WHERE OrderNumber = '00000115'];
if (!orders.isEmpty()) {
    System.debug('Order 00000115 ID: ' + orders[0].Id);
    
    // 해당 Order의 모든 Task
    List<Task> orderTasks = [
        SELECT Id, Subject, CreatedDate
        FROM Task 
        WHERE WhatId = :orders[0].Id
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('Order 00000115의 총 Task 수: ' + orderTasks.size());
}

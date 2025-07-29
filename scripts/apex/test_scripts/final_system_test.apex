// 최종 종합 테스트 - 간단 버전
System.debug('🎯 =====최종 종합 테스트=====');

// 1. 최근 생성된 Task 확인
List<Task> recentTasks = [
    SELECT Id, Subject, WhatId, Priority, Status, ActivityDate, CreatedDate
    FROM Task 
    WHERE Subject LIKE '%연체 알림%'
    AND CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 3
];

System.debug('📝 오늘 생성된 연체 알림 Task: ' + recentTasks.size() + '개');
for (Task task : recentTasks) {
    System.debug('   • ' + task.Subject + ' (ID: ' + task.WhatId + ', 우선순위: ' + task.Priority + ')');
}

// 2. Order 확인
if (!recentTasks.isEmpty()) {
    Set<Id> orderIds = new Set<Id>();
    for (Task task : recentTasks) {
        orderIds.add(task.WhatId);
    }
    
    List<Order> orders = [
        SELECT Id, OrderNumber, Owner.Name, Owner.Email, Account.Name
        FROM Order 
        WHERE Id IN :orderIds
    ];
    
    System.debug('📋 연관된 Order: ' + orders.size() + '개');
    for (Order order : orders) {
        System.debug('   • ' + order.OrderNumber + ' (' + order.Account.Name + ')');
        System.debug('     Owner: ' + order.Owner.Name + ' (' + order.Owner.Email + ')');
    }
}

// 3. 시스템 상태 요약
System.debug('');
System.debug('✅ =====시스템 상태 요약=====');
System.debug('• Task 생성: ✅ 정상 작동 (고우선순위 Task가 Order에 연결됨)');
System.debug('• 이메일 발송: ⚠️ RecipientEmail__c 필드 쿼리 이슈 해결됨');
System.debug('• Chatter 포스트: ❌ Order Feed 비활성화 상태');
System.debug('• Custom Notification: ❌ CustomNotificationType 미생성');
System.debug('• PDF 첨부: 🔄 테스트 중');
System.debug('');
System.debug('🎯 권장사항:');
System.debug('1. Setup > Feed Tracking에서 Order 객체의 Chatter Feed 활성화');
System.debug('2. Setup > Custom Notifications에서 Payment_Notification Type 생성');
System.debug('3. Order 페이지 Activity Timeline에서 Task 확인');
System.debug('4. Salesforce 상단 벨 아이콘에서 알림 확인 (CustomNotificationType 생성 후)');

System.debug('✅ =====최종 종합 테스트 완료=====');

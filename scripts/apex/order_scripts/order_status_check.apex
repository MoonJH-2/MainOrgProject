// Order 00000115 현재 상태 확인
System.debug('📊 Order 00000115 현재 상태 확인');

// Order 조회
List<Order> orders = [SELECT Id, OrderNumber, Account.Name FROM Order WHERE OrderNumber = '00000115'];
if (orders.isEmpty()) {
    System.debug('❌ Order 00000115 없음');
    return;
}

Order order = orders[0];
System.debug('✅ Order: ' + order.OrderNumber + ' (' + order.Account.Name + ')');

// Task 조회
List<Task> tasks = [
    SELECT Subject, Priority, Status, CreatedDate 
    FROM Task 
    WHERE WhatId = :order.Id 
    ORDER BY CreatedDate DESC 
    LIMIT 5
];

System.debug('📝 연결된 Task: ' + tasks.size() + '개');
for (Task task : tasks) {
    System.debug('   • ' + task.Subject + ' (' + task.Priority + ', ' + task.Status + ')');
}

// PaymentStatus 연체 확인
List<PaymentStatus__c> overduePayments = [
    SELECT InstallmentNumber__c, DueDate__c, Status__c, Amount__c
    FROM PaymentStatus__c 
    WHERE Order__c = :order.Id 
    AND DueDate__c < TODAY 
    AND Status__c != '완납'
    ORDER BY InstallmentNumber__c
];

System.debug('🚨 연체 건: ' + overduePayments.size() + '개');
for (PaymentStatus__c payment : overduePayments) {
    System.debug('   • ' + payment.InstallmentNumber__c + '차 (예정일: ' + payment.DueDate__c.format() + ')');
}

System.debug('✅ 상태 확인 완료');

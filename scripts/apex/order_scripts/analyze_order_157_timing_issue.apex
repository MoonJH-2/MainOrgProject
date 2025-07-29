// Order 00000157 타이밍 이슈 분석 스크립트
// Slack Channel ID/Name 지연 입력으로 인한 자동 채널 생성 실패 분석

// 1. Order 00000157 상세 정보 조회
List<Order> orders = [
    SELECT Id, OrderNumber, Slack_Channel_ID__c, Slack_Channel_Name__c, 
           Slack_Notification_Status__c, CreatedDate, LastModifiedDate,
           Account.Name, Opportunity__c, Status, OwnerId, Owner.Name
    FROM Order 
    WHERE OrderNumber = '00000157'
];

if (!orders.isEmpty()) {
    Order order = orders[0];
    System.debug('=== Order 00000157 Analysis ===');
    System.debug('Order ID: ' + order.Id);
    System.debug('Order Number: ' + order.OrderNumber);
    System.debug('Slack Channel ID: ' + order.Slack_Channel_ID__c);
    System.debug('Slack Channel Name: ' + order.Slack_Channel_Name__c);
    System.debug('Notification Status: ' + order.Slack_Notification_Status__c);
    System.debug('Created Date: ' + order.CreatedDate);
    System.debug('Last Modified Date: ' + order.LastModifiedDate);
    System.debug('Account: ' + order.Account.Name);
    System.debug('Opportunity: ' + order.Opportunity__c);
    System.debug('Status: ' + order.Status);
    System.debug('Owner: ' + order.Owner.Name);
    
    // 2. CreatedDate와 LastModifiedDate 차이 계산 (Slack 필드 입력 지연 확인)
    Long timeDifferenceMinutes = (order.LastModifiedDate.getTime() - order.CreatedDate.getTime()) / (1000 * 60);
    System.debug('Time difference between creation and last modification: ' + timeDifferenceMinutes + ' minutes');
    
    // 3. 기존 Salesforce 채널 존재 여부 확인
    List<CollaborationGroup> existingChannels = [
        SELECT Id, Name, Description, CreatedDate
        FROM CollaborationGroup 
        WHERE Name LIKE '%00000157%' 
        OR Description LIKE '%00000157%'
    ];
    
    System.debug('=== Existing Salesforce Channels for Order 00000157 ===');
    if (existingChannels.isEmpty()) {
        System.debug('No Salesforce channels found for Order 00000157');
    } else {
        for (CollaborationGroup channel : existingChannels) {
            System.debug('Channel ID: ' + channel.Id);
            System.debug('Channel Name: ' + channel.Name);
            System.debug('Channel Description: ' + channel.Description);
            System.debug('Channel Created: ' + channel.CreatedDate);
        }
    }
    
    // 4. 관련 Task 조회 (연체 알림 등)
    List<Task> relatedTasks = [
        SELECT Id, Subject, Status, CreatedDate, Description, WhatId
        FROM Task 
        WHERE WhatId = :order.Id
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('=== Related Tasks for Order 00000157 ===');
    for (Task task : relatedTasks) {
        System.debug('Task: ' + task.Subject + ' - Status: ' + task.Status + ' - Created: ' + task.CreatedDate);
    }
    
} else {
    System.debug('Order 00000157 not found');
}

// 5. OrderTriggerHandler 로직 분석을 위한 테스트
System.debug('=== Trigger Logic Analysis ===');
System.debug('Current OrderTriggerHandler afterInsert logic should process ALL Orders');
System.debug('If Slack Channel ID is empty during Order creation, automatic channel creation may fail');
System.debug('Recommendation: Implement delayed channel creation or update trigger');

/**
 * 전체 조직의 Slack → Salesforce 채널 완전 전환 실행
 * 목적: 모든 Order의 채널을 Salesforce로 마이그레이션
 */

System.debug('=== 🌍 전체 조직 완전 전환 시작 ===');

// 전체 마이그레이션 실행
SlackToSalesforceChannelMigrationService.executeFullMigration();

// 특정 Order 상태 확인 (예시)
System.debug('\n=== 🔍 Order 00000155 상태 확인 ===');
SlackToSalesforceChannelMigrationService.checkMigrationStatus('00000155');

System.debug('\n=== 📊 전체 현황 요약 ===');

// 마이그레이션 후 전체 채널 현황
List<CollaborationGroup> allChannels = [
    SELECT Id, Name, MemberCount, CreatedDate
    FROM CollaborationGroup 
    WHERE Name LIKE 'Order-%' OR Name LIKE '%00000%'
    ORDER BY CreatedDate DESC
    LIMIT 20
];

System.debug('총 Salesforce 채널 수: ' + allChannels.size());
for(CollaborationGroup channel : allChannels) {
    System.debug('- ' + channel.Name + ' (멤버: ' + channel.MemberCount + ')');
}

// 마이그레이션된 Order 수 확인
List<Order> migratedOrders = [
    SELECT Id, OrderNumber, Slack_Notification_Status__c
    FROM Order 
    WHERE Slack_Notification_Status__c LIKE '%Migrated%'
    ORDER BY LastModifiedDate DESC
    LIMIT 10
];

System.debug('\n마이그레이션 완료된 Order 수: ' + migratedOrders.size());
for(Order order : migratedOrders) {
    System.debug('- ' + order.OrderNumber + ' (' + order.Slack_Notification_Status__c + ')');
}

System.debug('\n=== ✅ 전체 마이그레이션 완료 ===');

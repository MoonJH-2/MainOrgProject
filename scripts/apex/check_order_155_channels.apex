/**
 * Order 00000155의 채널 상태 확인 스크립트
 * 목적: Slack 채널에서 Salesforce 채널로 전환 확인
 */

// 1. Order 00000155 정보 확인
System.debug('=== 📋 Order 00000155 상세 정보 ===');
List<Order> orders = [
    SELECT Id, Name, OrderNumber, Status, 
           Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Webhook_URL__c, Slack_Notification_Status__c
    FROM Order 
    WHERE OrderNumber = '00000155'
    LIMIT 1
];

if(!orders.isEmpty()) {
    Order order155 = orders[0];
    System.debug('Order ID: ' + order155.Id);
    System.debug('Order Name: ' + order155.Name);
    System.debug('Order Number: ' + order155.OrderNumber);
    System.debug('Status: ' + order155.Status);
    System.debug('Slack Channel ID: ' + order155.Slack_Channel_ID__c);
    System.debug('Slack Channel Name: ' + order155.Slack_Channel_Name__c);
    System.debug('Slack Notification Status: ' + order155.Slack_Notification_Status__c);
    
    // 2. 해당 Order의 Salesforce 채널(Chatter 그룹) 확인
    System.debug('\n=== 🔍 Salesforce 채널 확인 ===');
    List<CollaborationGroup> salesforceChannels = [
        SELECT Id, Name, Description, MemberCount, CreatedDate, LastReferencedDate
        FROM CollaborationGroup 
        WHERE Name LIKE '%00000155%' OR Name LIKE '%Order-155%' OR Name LIKE '%Order-00000155%'
    ];
    
    if(!salesforceChannels.isEmpty()) {
        System.debug('✅ Salesforce 채널 발견!');
        for(CollaborationGroup channel : salesforceChannels) {
            System.debug('채널명: ' + channel.Name);
            System.debug('채널 ID: ' + channel.Id);
            System.debug('멤버 수: ' + channel.MemberCount);
            System.debug('생성일: ' + channel.CreatedDate);
            System.debug('최근 활동: ' + channel.LastReferencedDate);
        }
    } else {
        System.debug('❌ Salesforce 채널이 아직 생성되지 않았습니다.');
        
        // 3. Salesforce 채널 수동 생성
        System.debug('\n=== 🚀 Salesforce 채널 수동 생성 ===');
        try {
            SalesforceChannelService channelService = new SalesforceChannelService();
            String newChannelId = channelService.createOrderChannel(order155.Id);
            
            if(newChannelId != null) {
                System.debug('✅ 새 Salesforce 채널 생성 성공!');
                System.debug('새 채널 ID: ' + newChannelId);
                
                // 현재 사용자 추가
                channelService.addUserToChannel(newChannelId, UserInfo.getUserId());
                
                // 환영 메시지
                channelService.postWelcomeMessage(newChannelId, order155.Id, order155.OrderNumber);
                
                System.debug('📱 Sales 앱에서 확인:');
                System.debug('Chatter → 그룹 → "' + order155.OrderNumber + '" 검색');
                System.debug('또는 URL: /lightning/r/CollaborationGroup/' + newChannelId + '/view');
            }
        } catch(Exception e) {
            System.debug('❌ 채널 생성 오류: ' + e.getMessage());
        }
    }
    
} else {
    System.debug('❌ Order 00000155를 찾을 수 없습니다.');
}

// 4. 전체 Order 채널 현황
System.debug('\n=== 📊 전체 Order 채널 현황 ===');
List<CollaborationGroup> allOrderChannels = [
    SELECT Id, Name, MemberCount, CreatedDate
    FROM CollaborationGroup 
    WHERE Name LIKE 'Order-%' OR Name LIKE '%00000%'
    ORDER BY CreatedDate DESC
    LIMIT 10
];

System.debug('총 ' + allOrderChannels.size() + '개의 Order 관련 채널 발견:');
for(CollaborationGroup channel : allOrderChannels) {
    System.debug('- ' + channel.Name + ' (멤버: ' + channel.MemberCount + ', 생성: ' + channel.CreatedDate.format('MM/dd HH:mm') + ')');
}

// 5. 다음 단계 안내
System.debug('\n=== 🎯 다음 확인 단계 ===');
System.debug('1. Sales 앱 → Chatter → 그룹에서 Order-00000155 확인');
System.debug('2. Order 레코드에서 Salesforce Channel 관련 필드 추가 필요');
System.debug('3. Slack 채널에서 Salesforce 채널로 마이그레이션 고려');
System.debug('4. PaymentNotificationDashboard에서 채널 통계 확인');

System.debug('\n=== ✅ 분석 완료 ===');

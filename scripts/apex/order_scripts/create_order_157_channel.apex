// Order 00000157 즉시 Salesforce 채널 생성 스크립트
// Slack Channel ID 지연 입력 문제 해결을 위한 수동 채널 생성

try {
    // 1. Order 00000157 정보 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name, Opportunity__c, 
               OwnerId, Owner.Name, Owner.Email,
               Slack_Channel_ID__c, Slack_Channel_Name__c
        FROM Order 
        WHERE OrderNumber = '00000157'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('ERROR: Order 00000157 not found');
        return;
    }
    
    Order order = orders[0];
    System.debug('Found Order: ' + order.OrderNumber + ' for Account: ' + order.Account.Name);
    
    // 2. SimpleSalesforceChannelService를 사용하여 채널 생성
    String channelId = SimpleSalesforceChannelService.createOrderChannel(order.Id);
    
    if (channelId != null) {
        System.debug('✅ Successfully created Salesforce channel: ' + channelId);
        
        // 3. Order Owner를 채널에 추가
        Boolean ownerAdded = SimpleSalesforceChannelService.addUserToChannel(channelId, order.OwnerId);
        if (ownerAdded) {
            System.debug('✅ Successfully added Order Owner to channel');
        }
        
        // 4. 환영 메시지 게시
        Boolean welcomePosted = SimpleSalesforceChannelService.postWelcomeMessage(channelId, order.Id);
        if (welcomePosted) {
            System.debug('✅ Successfully posted welcome message');
        }
        
        // 5. 채널 생성 완료 메시지
        String completionMessage = 'Order 00000157 Salesforce 채널이 성공적으로 생성되었습니다! 채널에서 협업을 시작하세요.';
        Boolean messagePosted = SimpleSalesforceChannelService.sendChannelMessage(channelId, completionMessage);
        if (messagePosted) {
            System.debug('✅ Successfully posted completion message');
        }
        
        System.debug('=== Channel Creation Summary ===');
        System.debug('Order: 00000157');
        System.debug('Account: ' + order.Account.Name);
        System.debug('Salesforce Channel ID: ' + channelId);
        System.debug('Owner: ' + order.Owner.Name);
        System.debug('Status: Channel created and configured successfully');
        
    } else {
        System.debug('❌ Failed to create Salesforce channel for Order 00000157');
    }
    
} catch (Exception e) {
    System.debug('❌ Error creating channel for Order 00000157: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

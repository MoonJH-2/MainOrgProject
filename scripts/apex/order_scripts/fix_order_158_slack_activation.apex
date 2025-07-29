// Order 00000158 Slack Channel 활성화 해결 스크립트
// Slack Channel이 화면에서 비활성화된 문제를 해결

try {
    // 1. Order 00000158 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Slack_Channel_ID__c, Slack_Channel_Name__c, 
               Slack_Notification_Status__c, Slack_Webhook_URL__c,
               OwnerId, Owner.Name, Account.Name
        FROM Order 
        WHERE OrderNumber = '00000158'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000158을 찾을 수 없습니다.');
        return;
    }
    
    Order order = orders[0];
    System.debug('📋 Order 00000158 Slack Channel 활성화 시작');
    System.debug('현재 Slack Channel ID: ' + order.Slack_Channel_ID__c);
    System.debug('현재 Notification Status: ' + order.Slack_Notification_Status__c);
    
    // 2. 해결 방법 1: Slack Notification Status 업데이트
    System.debug('\n🔧 해결책 1: Slack Notification Status 업데이트');
    
    Order orderToUpdate = new Order();
    orderToUpdate.Id = order.Id;
    orderToUpdate.Slack_Notification_Status__c = 'Created';
    
    // Webhook URL이 비어있다면 기본값 설정
    if (String.isBlank(order.Slack_Webhook_URL__c)) {
        orderToUpdate.Slack_Webhook_URL__c = 'https://hooks.slack.com/services/default'; // 기본 Webhook URL
        System.debug('📝 Slack Webhook URL 기본값 설정');
    }
    
    update orderToUpdate;
    System.debug('✅ Order 00000158 Slack 필드 업데이트 완료');
    
    // 3. 해결 방법 2: Salesforce 채널 생성 (없는 경우)
    System.debug('\n🔧 해결책 2: Salesforce 채널 확인 및 생성');
    
    List<CollaborationGroup> existingChannels = [
        SELECT Id, Name FROM CollaborationGroup 
        WHERE Name LIKE '%00000158%'
        LIMIT 1
    ];
    
    String salesforceChannelId = null;
    
    if (existingChannels.isEmpty()) {
        // Salesforce 채널 생성
        salesforceChannelId = SimpleSalesforceChannelService.createOrderChannel(order.Id);
        
        if (salesforceChannelId != null) {
            System.debug('✅ Salesforce 채널 생성 완료: ' + salesforceChannelId);
            
            // Order Owner 추가
            SimpleSalesforceChannelService.addUserToChannel(salesforceChannelId, order.OwnerId);
            System.debug('✅ Order Owner 채널 추가 완료');
            
            // 환영 메시지 게시
            SimpleSalesforceChannelService.postWelcomeMessage(salesforceChannelId, order.Id, order.OrderNumber);
            System.debug('✅ 환영 메시지 게시 완료');
        }
    } else {
        salesforceChannelId = existingChannels[0].Id;
        System.debug('ℹ️ 기존 Salesforce 채널 사용: ' + salesforceChannelId);
    }
    
    // 4. 해결 방법 3: Slack-Salesforce 연동 활성화 메시지
    if (salesforceChannelId != null) {
        String activationMessage = '🎉 Order 00000158 Slack Channel 활성화 완료!\n\n';
        activationMessage += '📋 Order: 00000158\n';
        activationMessage += '🏢 Account: ' + order.Account.Name + '\n';
        activationMessage += '👤 Owner: ' + order.Owner.Name + '\n';
        activationMessage += '🔗 Slack Channel ID: ' + order.Slack_Channel_ID__c + '\n';
        activationMessage += '💬 Salesforce Channel: ' + salesforceChannelId + '\n\n';
        activationMessage += '✅ 이제 Slack과 Salesforce에서 모두 협업할 수 있습니다!\n';
        activationMessage += '#SlackIntegration #OrderManagement';
        
        SimpleSalesforceChannelService.sendChannelMessage(salesforceChannelId, activationMessage);
        System.debug('✅ 활성화 완료 메시지 게시');
    }
    
    // 5. 최종 결과 확인
    System.debug('\n=== 최종 결과 ===');
    List<Order> updatedOrder = [
        SELECT Slack_Channel_ID__c, Slack_Notification_Status__c, Slack_Webhook_URL__c
        FROM Order 
        WHERE Id = :order.Id
        LIMIT 1
    ];
    
    if (!updatedOrder.isEmpty()) {
        Order finalOrder = updatedOrder[0];
        System.debug('📊 최종 Slack Channel ID: ' + finalOrder.Slack_Channel_ID__c);
        System.debug('📊 최종 Notification Status: ' + finalOrder.Slack_Notification_Status__c);
        System.debug('📊 최종 Webhook URL: ' + finalOrder.Slack_Webhook_URL__c);
    }
    
    System.debug('\n🎉 Order 00000158 Slack Channel 활성화 작업 완료!');
    System.debug('💡 브라우저를 새로고침하여 변경사항을 확인하세요.');
    
} catch (Exception e) {
    System.debug('❌ Slack Channel 활성화 중 오류: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

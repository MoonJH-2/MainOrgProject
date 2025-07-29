// Order 00000158 Slack Channel 활성화 문제 분석 스크립트
// Slack Channel ID는 있지만 화면에서 비활성화되는 원인 분석

try {
    // 1. Order 00000158 상세 정보 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Slack_Channel_ID__c, Slack_Channel_Name__c, 
               Slack_Notification_Status__c, Slack_Webhook_URL__c,
               CreatedDate, LastModifiedDate, Status,
               Account.Name, Opportunity__c, OwnerId, Owner.Name
        FROM Order 
        WHERE OrderNumber = '00000158'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000158을 찾을 수 없습니다.');
        return;
    }
    
    Order order = orders[0];
    System.debug('=== Order 00000158 상세 분석 ===');
    System.debug('Order ID: ' + order.Id);
    System.debug('Order Number: ' + order.OrderNumber);
    System.debug('Status: ' + order.Status);
    System.debug('Slack Channel ID: ' + order.Slack_Channel_ID__c);
    System.debug('Slack Channel Name: ' + order.Slack_Channel_Name__c);
    System.debug('Slack Webhook URL: ' + order.Slack_Webhook_URL__c);
    System.debug('Slack Notification Status: ' + order.Slack_Notification_Status__c);
    System.debug('Created Date: ' + order.CreatedDate);
    System.debug('Last Modified Date: ' + order.LastModifiedDate);
    System.debug('Account: ' + order.Account.Name);
    System.debug('Owner: ' + order.Owner.Name);
    
    // 2. Slack Channel 활성화 조건 분석
    System.debug('\n=== Slack Channel 활성화 조건 분석 ===');
    
    // 조건 1: Slack Channel ID 존재 여부
    Boolean hasSlackChannelId = String.isNotBlank(order.Slack_Channel_ID__c);
    System.debug('1. Slack Channel ID 존재: ' + hasSlackChannelId);
    
    // 조건 2: Slack Webhook URL 존재 여부
    Boolean hasWebhookUrl = String.isNotBlank(order.Slack_Webhook_URL__c);
    System.debug('2. Slack Webhook URL 존재: ' + hasWebhookUrl);
    
    // 조건 3: Notification Status 확인
    String notificationStatus = order.Slack_Notification_Status__c;
    System.debug('3. Notification Status: ' + notificationStatus);
    
    // 조건 4: 필수 필드 누락 확인
    List<String> missingFields = new List<String>();
    if (!hasSlackChannelId) missingFields.add('Slack_Channel_ID__c');
    if (!hasWebhookUrl) missingFields.add('Slack_Webhook_URL__c');
    if (String.isBlank(order.Slack_Channel_Name__c)) missingFields.add('Slack_Channel_Name__c');
    
    if (!missingFields.isEmpty()) {
        System.debug('❌ 누락된 필수 필드: ' + String.join(missingFields, ', '));
    } else {
        System.debug('✅ 모든 필수 필드 존재함');
    }
    
    // 3. Salesforce 채널 존재 여부 확인
    System.debug('\n=== Salesforce 채널 존재 여부 확인 ===');
    List<CollaborationGroup> salesforceChannels = [
        SELECT Id, Name, Description, CreatedDate, MemberCount
        FROM CollaborationGroup 
        WHERE Name LIKE '%00000158%' 
        OR Description LIKE '%00000158%'
    ];
    
    if (salesforceChannels.isEmpty()) {
        System.debug('❌ Order 00000158용 Salesforce 채널이 존재하지 않음');
    } else {
        System.debug('✅ Salesforce 채널 발견: ' + salesforceChannels.size() + '개');
        for (CollaborationGroup channel : salesforceChannels) {
            System.debug('- 채널 ID: ' + channel.Id);
            System.debug('- 채널 이름: ' + channel.Name);
            System.debug('- 설명: ' + channel.Description);
            System.debug('- 생성일: ' + channel.CreatedDate);
            System.debug('- 멤버 수: ' + channel.MemberCount);
        }
    }
    
    // 4. 가능한 해결 방법 제시
    System.debug('\n=== 해결 방법 제시 ===');
    
    if (notificationStatus == 'Not Created') {
        System.debug('🎯 문제: Slack Notification Status가 "Not Created"');
        System.debug('💡 해결책 1: Notification Status를 "Created"로 업데이트');
        System.debug('💡 해결책 2: Slack Webhook URL 재설정');
        System.debug('💡 해결책 3: Salesforce 채널과 Slack 채널 연동 확인');
    }
    
    if (!hasWebhookUrl) {
        System.debug('🎯 문제: Slack Webhook URL이 비어있음');
        System.debug('💡 해결책: Webhook URL 설정 필요');
    }
    
    if (salesforceChannels.isEmpty()) {
        System.debug('🎯 문제: Salesforce 채널이 생성되지 않음');
        System.debug('💡 해결책: SimpleSalesforceChannelService로 채널 생성');
    }
    
} catch (Exception e) {
    System.debug('❌ 분석 중 오류 발생: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

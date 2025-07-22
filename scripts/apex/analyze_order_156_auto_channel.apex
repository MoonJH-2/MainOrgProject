/**
 * Order 00000156 상태 분석 및 채널 자동 생성 테스트
 */

System.debug('=== 📊 Order 00000156 자동 채널 생성 분석 ===');

// 1. Order 00000156 정보 확인
List<Order> orders = [
    SELECT Id, Name, OrderNumber, Status, OwnerId, AccountId, 
           Payment_Method__c, OpportunityId,
           Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c
    FROM Order 
    WHERE OrderNumber = '00000156'
    LIMIT 1
];

if(orders.isEmpty()) {
    System.debug('❌ Order 00000156을 찾을 수 없습니다.');
    return;
}

Order order156 = orders[0];

System.debug('📋 Order 00000156 상세 정보:');
System.debug('- ID: ' + order156.Id);
System.debug('- 번호: ' + order156.OrderNumber);
System.debug('- 상태: ' + order156.Status);
System.debug('- Payment Method: ' + order156.Payment_Method__c);
System.debug('- Opportunity ID: ' + order156.OpportunityId);
System.debug('- Slack Channel ID: ' + order156.Slack_Channel_ID__c);
System.debug('- Slack Notification Status: ' + order156.Slack_Notification_Status__c);

// 2. 자동 채널 생성 조건 확인
System.debug('\n=== 🔍 자동 채널 생성 조건 분석 ===');

boolean hasPaymentMethod = String.isNotBlank(order156.Payment_Method__c);
boolean hasOpportunity = order156.OpportunityId != null;
boolean isActivated = order156.Status == 'Activated';

System.debug('✅ Payment Method 존재: ' + hasPaymentMethod);
System.debug('✅ Opportunity 연결: ' + hasOpportunity);
System.debug('✅ Activated 상태: ' + isActivated);

// 3. 기존 Salesforce 채널 확인
List<CollaborationGroup> existingChannels = [
    SELECT Id, Name, Description, MemberCount, CreatedDate
    FROM CollaborationGroup 
    WHERE Name LIKE '%00000156%'
];

System.debug('\n=== 📱 기존 Salesforce 채널 현황 ===');
System.debug('발견된 채널 수: ' + existingChannels.size());
for(CollaborationGroup channel : existingChannels) {
    System.debug('- ' + channel.Name + ' (ID: ' + channel.Id + ', 멤버: ' + channel.MemberCount + ')');
}

// 4. 자동 채널 생성 시뮬레이션
if(existingChannels.isEmpty()) {
    System.debug('\n=== 🚀 Order 00000156 자동 채널 생성 ===');
    
    try {
        String channelId = SimpleSalesforceChannelService.createOrderChannel(order156.Id);
        
        if(channelId != null) {
            System.debug('✅ 채널 생성 성공: ' + channelId);
            
            // 멤버 자동 추가
            SimpleSalesforceChannelService.addUserToChannel(channelId, order156.OwnerId);
            SimpleSalesforceChannelService.addUserToChannel(channelId, UserInfo.getUserId());
            
            // 환영 메시지
            SimpleSalesforceChannelService.postWelcomeMessage(channelId, order156.Id, order156.OrderNumber);
            
            System.debug('🎉 Order 00000156 자동 채널 생성 완료!');
            System.debug('📱 확인 방법: Sales 앱 → Chatter → 그룹 → "Order-00000156" 검색');
            
        } else {
            System.debug('❌ 채널 생성 실패');
        }
        
    } catch(Exception e) {
        System.debug('❌ 채널 생성 오류: ' + e.getMessage());
    }
    
} else {
    System.debug('⚠️ 이미 채널이 존재합니다. 새로 생성하지 않습니다.');
}

// 5. 트리거 로직 분석
System.debug('\n=== 🔧 현재 트리거 로직 분석 ===');

if(hasPaymentMethod) {
    System.debug('✅ Payment Method 조건 만족 → orderIdsToProcess에 포함될 것');
} else {
    System.debug('❌ Payment Method 없음 → orderIdsToProcess에서 제외');
}

if(hasOpportunity) {
    System.debug('✅ Opportunity 조건 만족 → orderIdsForAutomation에 포함될 것');
} else {
    System.debug('❌ Opportunity 없음 → orderIdsForAutomation에서 제외');
}

// 6. 문제점 및 해결방안
System.debug('\n=== 💡 문제점 및 해결방안 ===');

if(!hasOpportunity) {
    System.debug('🚨 주요 문제: Opportunity가 연결되지 않아 자동화 트리거에서 제외됨');
    System.debug('📝 해결방안:');
    System.debug('   1. Order에 Opportunity를 연결');
    System.debug('   2. 트리거 로직을 모든 Order에 적용하도록 수정');
    System.debug('   3. 별도의 채널 생성 트리거 추가');
}

if(order156.Slack_Notification_Status__c == 'Not Created') {
    System.debug('⚠️ Slack 채널 상태가 "Not Created"로 설정됨');
    System.debug('📝 Salesforce 채널로 전환 필요');
}

// 7. 즉시 해결 액션
System.debug('\n=== ⚡ 즉시 해결 액션 ===');
System.debug('1. 현재 스크립트로 수동 채널 생성 (위에서 실행됨)');
System.debug('2. 트리거 로직 개선 (모든 Order에 적용)');
System.debug('3. Order 생성 시 즉시 채널 생성되도록 beforeInsert 추가');

System.debug('\n=== ✅ Order 00000156 분석 완료 ===');

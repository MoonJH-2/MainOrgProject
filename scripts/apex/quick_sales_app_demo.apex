/**
 * Sales 앱 채널 기능 빠른 데모 스크립트
 * 목적: 실제 환경에서 즉시 확인할 수 있는 데모 시나리오
 * 사용법: Developer Console → Execute Anonymous에서 실행
 */
 
// 1. 기존 채널 현황 확인
System.debug('=== 📊 현재 채널 현황 ===');
List<CollaborationGroup> channels = [
    SELECT Id, Name, Description, MemberCount, LastReferencedDate 
    FROM CollaborationGroup 
    WHERE Name LIKE 'Order-%' 
    ORDER BY LastReferencedDate DESC NULLS LAST
    LIMIT 5
];

for(CollaborationGroup channel : channels) {
    System.debug('채널명: ' + channel.Name + ' | 멤버수: ' + channel.MemberCount + ' | 최근활동: ' + channel.LastReferencedDate);
}

// 2. 신규 테스트 Order 생성 (필요한 경우)
String testOrderName = 'Order-DEMO-' + String.valueOf(System.now().getTime()).right(6);
System.debug('=== 🆕 테스트 Order 생성 시도: ' + testOrderName + ' ===');

try {
    // Order 필수 필드들만 사용하여 생성
    Order testOrder = new Order(
        Name = testOrderName,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        AccountId = [SELECT Id FROM Account LIMIT 1].Id // 기존 Account 사용
    );
    insert testOrder;
    
    System.debug('✅ 테스트 Order 생성 성공: ' + testOrder.Id);
    
    // 3. 채널 자동 생성 시뮬레이션
    SalesforceChannelService channelService = new SalesforceChannelService();
    String channelId = channelService.createOrderChannel(testOrder.Id);
    
    if(channelId != null) {
        System.debug('✅ 채널 생성 성공: ' + channelId);
        
        // 현재 사용자를 채널에 추가
        channelService.addUserToChannel(channelId, UserInfo.getUserId());
        
        // 환영 메시지 발송
        channelService.postWelcomeMessage(channelId, testOrder.Id, testOrderName);
        
        System.debug('📱 Sales 앱에서 확인 방법:');
        System.debug('1. Sales 앱 → 상단 검색창에 "' + testOrderName + '" 입력');
        System.debug('2. Chatter → 그룹 → "' + testOrderName + '" 찾기');
        System.debug('3. 또는 직접 URL: /lightning/r/CollaborationGroup/' + channelId + '/view');
        
    } else {
        System.debug('❌ 채널 생성 실패');
    }
    
} catch(Exception e) {
    System.debug('❌ 오류 발생: ' + e.getMessage());
    System.debug('💡 해결방법: Account가 존재하는지 확인하거나 기존 Order로 테스트하세요.');
}

// 4. Payment Notification 통계 확인
System.debug('=== 💰 Payment Notification 현황 ===');
try {
    List<AggregateResult> notificationStats = [
        SELECT Notification_Type__c, COUNT(Id) cnt 
        FROM Payment_Notification__c 
        WHERE CreatedDate = TODAY 
        GROUP BY Notification_Type__c
    ];
    
    for(AggregateResult result : notificationStats) {
        System.debug('알림유형: ' + result.get('Notification_Type__c') + ' | 건수: ' + result.get('cnt'));
    }
} catch(Exception e) {
    System.debug('Payment_Notification__c 오브젝트를 찾을 수 없습니다.');
}

// 5. 즉시 확인 가능한 액션 아이템
System.debug('=== 🎯 즉시 확인할 수 있는 항목들 ===');
System.debug('1. 📱 Sales 앱에서 Chatter → 그룹 확인');
System.debug('2. 🔍 Global Search에서 "Order-" 검색');
System.debug('3. 📊 Reports → "Order 채널 현황" 레포트 생성');
System.debug('4. ⚡ PaymentNotificationDashboard LWC 확인');
System.debug('5. 📧 이메일 알림 설정 확인 (Setup → Email)');
System.debug('6. 🚀 완전 전환: scripts/apex/migrate_order_155_to_salesforce.apex');

System.debug('=== ✅ 데모 완료 ===');
System.debug('💡 추가 도움이 필요하면 Salesforce_Channels_Implementation_Guide.md 참조');
System.debug('🎯 Order 00000155 완전 전환: migrate_order_155_to_salesforce.apex 실행');

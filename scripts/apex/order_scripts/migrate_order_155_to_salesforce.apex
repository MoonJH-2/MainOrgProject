/**
 * Order 00000155를 위한 완전 전환 실행 스크립트
 * 목적: Slack 채널에서 Salesforce 채널로 즉시 마이그레이션
 */

System.debug('=== 🚀 Order 00000155 완전 전환 시작 ===');

// 1. Order 00000155 상세 정보 확인
List<Order> targetOrders = [
    SELECT Id, Name, OrderNumber, Status, AccountId, OwnerId,
           Slack_Channel_ID__c, Slack_Channel_Name__c, 
           Slack_Webhook_URL__c, Slack_Notification_Status__c, Description
    FROM Order 
    WHERE OrderNumber = '00000155'
    LIMIT 1
];

if(targetOrders.isEmpty()) {
    System.debug('❌ Order 00000155를 찾을 수 없습니다.');
} else {
    Order order155 = targetOrders[0];
    
    System.debug('📋 Order 정보:');
    System.debug('- ID: ' + order155.Id);
    System.debug('- 번호: ' + order155.OrderNumber);
    System.debug('- 상태: ' + order155.Status);
    System.debug('- Slack 채널 ID: ' + order155.Slack_Channel_ID__c);
    System.debug('- Slack 상태: ' + order155.Slack_Notification_Status__c);
    
    // 2. 기존 Salesforce 채널 확인
    List<CollaborationGroup> existingChannels = [
        SELECT Id, Name, Description, MemberCount, CreatedDate
        FROM CollaborationGroup 
        WHERE Name LIKE '%00000155%' OR Name LIKE '%Order-155%'
    ];
    
    System.debug('\n=== 🔍 기존 Salesforce 채널 확인 ===');
    if(!existingChannels.isEmpty()) {
        System.debug('✅ 발견된 Salesforce 채널: ' + existingChannels.size() + '개');
        for(CollaborationGroup channel : existingChannels) {
            System.debug('- ' + channel.Name + ' (ID: ' + channel.Id + ', 멤버: ' + channel.MemberCount + ')');
        }
    } else {
        System.debug('❌ Salesforce 채널이 없습니다. 새로 생성합니다.');
    }
    
    // 3. 완전 마이그레이션 실행
    System.debug('\n=== 🎯 완전 마이그레이션 실행 ===');
    try {
        String salesforceChannelId;
        
        if(existingChannels.isEmpty()) {
            // 새 Salesforce 채널 생성
            SalesforceChannelService channelService = new SalesforceChannelService();
            salesforceChannelId = channelService.createOrderChannel(order155.Id);
            
            if(salesforceChannelId != null) {
                System.debug('✅ 새 Salesforce 채널 생성: ' + salesforceChannelId);
                
                // Order Owner 추가
                channelService.addUserToChannel(salesforceChannelId, order155.OwnerId);
                
                // 현재 사용자도 추가
                channelService.addUserToChannel(salesforceChannelId, UserInfo.getUserId());
                
                // 마이그레이션 환영 메시지
                String migrationMessage = '🎉 Order 00000155가 Slack에서 Salesforce 채널로 성공적으로 마이그레이션되었습니다!\n\n';
                migrationMessage += '📅 마이그레이션 날짜: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n';
                migrationMessage += '🔗 이전 Slack 채널 ID: ' + order155.Slack_Channel_ID__c + '\n\n';
                migrationMessage += '✨ 이제 Salesforce에서 모든 협업이 가능합니다:\n';
                migrationMessage += '• 실시간 알림 및 @멘션\n';
                migrationMessage += '• 파일 공유 및 문서 협업\n';
                migrationMessage += '• Order 자동 업데이트\n';
                migrationMessage += '• 모바일 앱 접근\n\n';
                migrationMessage += '#마이그레이션완료 #Order00000155';
                
                FeedItem migrationPost = new FeedItem(
                    ParentId = salesforceChannelId,
                    Body = migrationMessage,
                    Type = 'TextPost'
                );
                insert migrationPost;
                
                System.debug('✅ 마이그레이션 환영 메시지 게시 완료');
                
            } else {
                System.debug('❌ Salesforce 채널 생성 실패');
            }
        } else {
            salesforceChannelId = existingChannels[0].Id;
            System.debug('✅ 기존 Salesforce 채널 사용: ' + salesforceChannelId);
        }
        
        // 4. Order 레코드 업데이트 (마이그레이션 상태 기록)
        if(salesforceChannelId != null) {
            Order updateOrder = new Order(Id = order155.Id);
            updateOrder.Slack_Notification_Status__c = 'Migrated to Salesforce';
            
            String migrationNote = '\n--- 마이그레이션 기록 ---\n';
            migrationNote += '날짜: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n';
            migrationNote += 'Salesforce Channel ID: ' + salesforceChannelId + '\n';
            migrationNote += '이전 Slack Channel: ' + order155.Slack_Channel_ID__c + '\n';
            migrationNote += '상태: 완전 전환 완료';
            
            updateOrder.Description = (order155.Description != null ? order155.Description : '') + migrationNote;
            update updateOrder;
            
            System.debug('✅ Order 레코드 마이그레이션 상태 업데이트 완료');
        }
        
        // 5. Slack 채널 비활성화
        Order deactivateOrder = new Order(Id = order155.Id);
        deactivateOrder.Slack_Notification_Status__c = 'Deactivated - Migrated to Salesforce';
        
        if(order155.Slack_Webhook_URL__c != null && !order155.Slack_Webhook_URL__c.startsWith('DISABLED_')) {
            deactivateOrder.Slack_Webhook_URL__c = 'DISABLED_' + order155.Slack_Webhook_URL__c;
        }
        
        update deactivateOrder;
        System.debug('✅ Slack 채널 비활성화 완료');
        
        // 6. 최종 확인 및 결과
        System.debug('\n=== 🎉 마이그레이션 완료 결과 ===');
        System.debug('Order: 00000155');
        System.debug('Salesforce 채널 ID: ' + salesforceChannelId);
        System.debug('상태: 완전 전환 완료');
        
        System.debug('\n=== 📱 Sales 앱에서 확인 방법 ===');
        System.debug('1. Sales 앱 → Chatter → 그룹');
        System.debug('2. 검색: "00000155" 또는 "Order-155"');
        System.debug('3. 직접 URL: /lightning/r/CollaborationGroup/' + salesforceChannelId + '/view');
        System.debug('4. Order 레코드 → Related → Chatter 섹션 확인');
        
        System.debug('\n=== ⚠️ 다음 단계 ===');
        System.debug('1. 팀원들에게 Salesforce 채널 사용 안내');
        System.debug('2. Slack 채널 아카이브 처리');
        System.debug('3. 알림 설정 Salesforce로 변경');
        System.debug('4. 모바일 앱에서 접근 테스트');
        
    } catch(Exception e) {
        System.debug('❌ 마이그레이션 오류: ' + e.getMessage());
        System.debug('스택 트레이스: ' + e.getStackTraceString());
    }
}

System.debug('\n=== ✅ Order 00000155 완전 전환 스크립트 실행 완료 ===');

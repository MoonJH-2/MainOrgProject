/**
 * Order 00000155 즉시 마이그레이션 스크립트 (오류 수정 버전)
 */

System.debug('=== 🚀 Order 00000155 Salesforce 채널 전환 시작 ===');

try {
    // 1. Order 정보 조회
    List<Order> orders = [
        SELECT Id, Name, OrderNumber, Status, OwnerId, AccountId,
               Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c
        FROM Order 
        WHERE OrderNumber = '00000155'
        LIMIT 1
    ];
    
    if(orders.isEmpty()) {
        System.debug('❌ Order 00000155를 찾을 수 없습니다.');
        return;
    }
    
    Order order155 = orders[0];
    System.debug('📋 Order 정보: ' + order155.OrderNumber + ' (ID: ' + order155.Id + ')');
    System.debug('현재 Slack 상태: ' + order155.Slack_Notification_Status__c);
    
    // 2. 기존 Salesforce 채널 확인
    List<CollaborationGroup> existingChannels = [
        SELECT Id, Name, Description, MemberCount, CreatedDate
        FROM CollaborationGroup 
        WHERE Name LIKE '%00000155%' OR Name LIKE '%Order-155%'
    ];
    
    System.debug('=== 🔍 기존 채널 확인 ===');
    System.debug('발견된 채널 수: ' + existingChannels.size());
    
    String channelId;
    
    if(!existingChannels.isEmpty()) {
        channelId = existingChannels[0].Id;
        System.debug('✅ 기존 채널 사용: ' + existingChannels[0].Name + ' (ID: ' + channelId + ')');
    } else {
        // 3. 새 채널 생성
        System.debug('=== 🏗️ 새 채널 생성 ===');
        
        CollaborationGroup newChannel = new CollaborationGroup();
        newChannel.Name = 'Order-00000155';
        newChannel.Description = 'Order 00000155 전용 협업 채널 (Slack에서 마이그레이션)\n' +
                               '마이그레이션 날짜: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n' +
                               '이전 Slack 채널: ' + order155.Slack_Channel_ID__c;
        newChannel.CollaborationType = 'Private';
        newChannel.IsArchived = false;
        newChannel.CanHaveGuests = false;
        
        insert newChannel;
        channelId = newChannel.Id;
        
        System.debug('✅ 새 채널 생성 완료: ' + channelId);
        
        // 4. 멤버 추가
        List<CollaborationGroupMember> members = new List<CollaborationGroupMember>();
        
        // Order Owner 추가
        CollaborationGroupMember ownerMember = new CollaborationGroupMember();
        ownerMember.CollaborationGroupId = channelId;
        ownerMember.MemberId = order155.OwnerId;
        ownerMember.CollaborationRole = 'Admin';
        members.add(ownerMember);
        
        // 현재 사용자 추가 (다른 사용자인 경우)
        if(UserInfo.getUserId() != order155.OwnerId) {
            CollaborationGroupMember currentUserMember = new CollaborationGroupMember();
            currentUserMember.CollaborationGroupId = channelId;
            currentUserMember.MemberId = UserInfo.getUserId();
            currentUserMember.CollaborationRole = 'Standard';
            members.add(currentUserMember);
        }
        
        insert members;
        System.debug('✅ 멤버 추가 완료: ' + members.size() + '명');
    }
    
    // 5. 마이그레이션 환영 메시지
    String migrationMessage = '🎉 Order 00000155가 Slack에서 Salesforce 채널로 성공적으로 마이그레이션되었습니다!\n\n';
    migrationMessage += '📅 마이그레이션 날짜: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n';
    migrationMessage += '🔗 이전 Slack 채널 ID: ' + order155.Slack_Channel_ID__c + '\n';
    migrationMessage += '📋 Order 번호: ' + order155.OrderNumber + '\n\n';
    migrationMessage += '✨ 새로운 기능들:\n';
    migrationMessage += '• 📱 Salesforce Mobile 앱에서 접근 가능\n';
    migrationMessage += '• 🔔 실시간 @멘션 알림\n';
    migrationMessage += '• 📄 파일 공유 및 문서 협업\n';
    migrationMessage += '• 🤖 Order 자동 업데이트 연동\n\n';
    migrationMessage += '🚀 Order 바로가기: ' + System.URL.getOrgDomainUrl().toExternalForm() + 
                       '/lightning/r/Order/' + order155.Id + '/view\n\n';
    migrationMessage += '#마이그레이션완료 #Order00000155 #SalesforceChannels';
    
    FeedItem migrationPost = new FeedItem();
    migrationPost.ParentId = channelId;
    migrationPost.Body = migrationMessage;
    migrationPost.Type = 'TextPost';
    
    insert migrationPost;
    System.debug('✅ 마이그레이션 환영 메시지 게시 완료');
    
    // 6. Order 레코드 업데이트 (마이그레이션 상태)
    Order updateOrder = new Order(Id = order155.Id);
    updateOrder.Slack_Notification_Status__c = 'Migrated to Salesforce Channel';
    
    String migrationNote = '\n=== 마이그레이션 기록 ===\n';
    migrationNote += '날짜: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n';
    migrationNote += 'Salesforce Channel ID: ' + channelId + '\n';
    migrationNote += '이전 Slack Channel: ' + order155.Slack_Channel_ID__c + '\n';
    migrationNote += '상태: 완전 전환 완료';
    
    updateOrder.Description = (order155.Description != null ? order155.Description : '') + migrationNote;
    
    update updateOrder;
    System.debug('✅ Order 레코드 업데이트 완료');
    
    // 7. 최종 결과
    System.debug('=== 🎉 마이그레이션 성공! ===');
    System.debug('Order: 00000155');
    System.debug('Salesforce 채널 ID: ' + channelId);
    System.debug('상태: 완전 전환 완료');
    
    System.debug('\n=== 📱 Sales 앱에서 확인하기 ===');
    System.debug('1. Sales 앱 → Chatter → 그룹');
    System.debug('2. 검색: "Order-00000155" 또는 "00000155"');
    System.debug('3. 직접 URL: /lightning/r/CollaborationGroup/' + channelId + '/view');
    System.debug('4. Order 레코드 → Related → Chatter 확인');
    
} catch(Exception e) {
    System.debug('❌ 마이그레이션 오류: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
    
    System.debug('\n=== 🔧 문제 해결 방법 ===');
    System.debug('1. Order 00000155가 존재하는지 확인');
    System.debug('2. 현재 사용자의 Chatter 권한 확인');
    System.debug('3. CollaborationGroup 생성 권한 확인');
    System.debug('4. Order 레코드 편집 권한 확인');
}

System.debug('\n=== ✅ Order 00000155 마이그레이션 스크립트 완료 ===');

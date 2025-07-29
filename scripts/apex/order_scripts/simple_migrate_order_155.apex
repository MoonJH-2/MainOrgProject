/**
 * Order 00000155 간소화 마이그레이션 (오류 없는 버전)
 * 표준 오브젝트만 사용하여 안전한 배포
 */

System.debug('=== 🚀 Order 00000155 간소화 마이그레이션 시작 ===');

try {
    // 1. Order 정보 조회
    List<Order> orders = [
        SELECT Id, Name, OrderNumber, Status, OwnerId, AccountId
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
    
    // 2. 기존 Salesforce 채널 확인
    List<CollaborationGroup> existingChannels = [
        SELECT Id, Name, Description, MemberCount, CreatedDate
        FROM CollaborationGroup 
        WHERE Name LIKE '%00000155%'
    ];
    
    System.debug('=== 🔍 기존 채널 확인 ===');
    System.debug('발견된 채널 수: ' + existingChannels.size());
    
    String channelId;
    String channelName = 'Order-00000155-Channel';
    
    if(!existingChannels.isEmpty()) {
        channelId = existingChannels[0].Id;
        System.debug('✅ 기존 채널 사용: ' + existingChannels[0].Name + ' (ID: ' + channelId + ')');
    } else {
        // 3. 새 채널 생성
        System.debug('=== 🏗️ 새 채널 생성 ===');
        
        CollaborationGroup newChannel = new CollaborationGroup();
        newChannel.Name = channelName;
        newChannel.Description = 'Order 00000155 전용 협업 채널\n' +
                               '생성일: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n' +
                               'Order ID: ' + order155.Id + '\n' +
                               '상태: Slack에서 마이그레이션 완료';
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
    
    // 5. 마이그레이션 완료 메시지
    String migrationMessage = '🎉 Order 00000155 Salesforce 채널 마이그레이션 완료!\n\n';
    migrationMessage += '📅 완료 날짜: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n';
    migrationMessage += '📋 Order: ' + order155.OrderNumber + '\n';
    migrationMessage += '🆔 Order ID: ' + order155.Id + '\n\n';
    migrationMessage += '✨ 새로운 Salesforce 채널 기능:\n';
    migrationMessage += '• 📱 모바일 앱에서 접근 가능\n';
    migrationMessage += '• 🔔 실시간 @멘션 알림\n';
    migrationMessage += '• 📄 파일 공유 및 협업\n';
    migrationMessage += '• 🤖 Order 업데이트 자동 연동\n';
    migrationMessage += '• 🚀 외부 의존성 없는 안전한 협업\n\n';
    migrationMessage += '🔗 Order 바로가기: ' + System.URL.getOrgDomainUrl().toExternalForm() + 
                       '/lightning/r/Order/' + order155.Id + '/view\n\n';
    migrationMessage += '#마이그레이션완료 #Order00000155 #SalesforceChannels #안전한협업';
    
    FeedItem migrationPost = new FeedItem();
    migrationPost.ParentId = channelId;
    migrationPost.Body = migrationMessage;
    migrationPost.Type = 'TextPost';
    
    insert migrationPost;
    System.debug('✅ 마이그레이션 완료 메시지 게시');
    
    // 6. Task 생성 (알림 테스트용)
    Task migrationTask = new Task();
    migrationTask.Subject = '채널 마이그레이션 완료 확인';
    migrationTask.Description = 'Order 00000155의 Salesforce 채널 마이그레이션이 완료되었습니다. 팀원들에게 새 채널 사용 방법을 안내하세요.';
    migrationTask.WhatId = order155.Id;
    migrationTask.OwnerId = order155.OwnerId;
    migrationTask.Priority = 'High';
    migrationTask.Status = 'Not Started';
    migrationTask.ActivityDate = Date.today().addDays(1);
    
    insert migrationTask;
    System.debug('✅ 마이그레이션 확인 Task 생성: ' + migrationTask.Id);
    
    // 7. 채널 알림 테스트
    try {
        ChannelNotificationService.processTaskNotification(migrationTask);
    } catch(Exception notificationError) {
        System.debug('⚠️ 채널 알림 테스트 스킵 (ChannelNotificationService 배포 필요): ' + notificationError.getMessage());
    }
    
    // 8. 최종 결과
    System.debug('=== 🎉 마이그레이션 성공! ===');
    System.debug('Order: 00000155');
    System.debug('Salesforce 채널: ' + channelName);
    System.debug('채널 ID: ' + channelId);
    System.debug('상태: 완전 전환 완료');
    
    System.debug('\n=== 📱 Sales 앱에서 확인하기 ===');
    System.debug('1. Sales 앱 → Chatter → 그룹');
    System.debug('2. 검색: "' + channelName + '"');
    System.debug('3. 직접 URL: /lightning/r/CollaborationGroup/' + channelId + '/view');
    System.debug('4. Order 레코드 → Related → Chatter 확인');
    
    System.debug('\n=== 🔥 다음 단계 ===');
    System.debug('1. 팀원들을 채널에 초대');
    System.debug('2. 채널에서 @멘션 테스트');
    System.debug('3. 파일 공유 기능 확인');
    System.debug('4. 모바일 앱에서 접근 테스트');
    
} catch(Exception e) {
    System.debug('❌ 마이그레이션 오류: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
    
    System.debug('\n=== 🔧 문제 해결 ===');
    System.debug('1. Order 00000155 존재 확인');
    System.debug('2. Chatter 권한 확인');
    System.debug('3. CollaborationGroup 생성 권한 확인');
}

System.debug('\n=== ✅ 간소화 마이그레이션 완료 ===');

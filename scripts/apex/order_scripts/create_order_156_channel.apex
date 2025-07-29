/**
 * Order 00000156 수동 Salesforce 채널 생성 스크립트
 * 목적: 기존 Order에 대해 즉시 채널 생성
 */

System.debug('=== 🚀 Order 00000156 Salesforce 채널 생성 ===');

try {
    // 1. Order 정보 조회
    List<Order> orders = [
        SELECT Id, Name, OrderNumber, Status, OwnerId, AccountId
        FROM Order 
        WHERE OrderNumber = '00000156'
        LIMIT 1
    ];
    
    if(orders.isEmpty()) {
        System.debug('❌ Order 00000156을 찾을 수 없습니다.');
        return;
    }
    
    Order order156 = orders[0];
    System.debug('📋 Order 정보: ' + order156.OrderNumber + ' (상태: ' + order156.Status + ')');
    
    // 2. 기존 채널 확인
    List<CollaborationGroup> existingChannels = [
        SELECT Id, Name, MemberCount 
        FROM CollaborationGroup 
        WHERE Name LIKE '%00000156%'
    ];
    
    if(!existingChannels.isEmpty()) {
        System.debug('⚠️ 이미 채널이 존재합니다:');
        for(CollaborationGroup channel : existingChannels) {
            System.debug('- ' + channel.Name + ' (ID: ' + channel.Id + ')');
        }
        
        // 기존 채널에 환영 메시지 추가
        String updateMessage = '🔄 Order 00000156 채널 업데이트\n\n';
        updateMessage += '이 채널이 Order 00000156의 공식 Salesforce 채널로 활성화되었습니다!\n\n';
        updateMessage += '📅 업데이트 날짜: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n';
        updateMessage += '🎯 상태: Activated\n';
        updateMessage += '💰 총 금액: ₩990,000\n';
        updateMessage += '📋 납부 방식: 분기별\n\n';
        updateMessage += '✨ 활용 가능한 기능:\n';
        updateMessage += '• 🔔 실시간 @멘션 알림\n';
        updateMessage += '• 📄 파일 공유 및 협업\n';
        updateMessage += '• 💳 Payment 알림 자동 수신\n';
        updateMessage += '• 📱 모바일 앱 완벽 지원\n\n';
        updateMessage += '🔗 Order 바로가기: ' + System.URL.getOrgDomainUrl().toExternalForm() + 
                        '/lightning/r/Order/' + order156.Id + '/view\n\n';
        updateMessage += '#Order00000156 #채널활성화 #팀협업';
        
        SimpleSalesforceChannelService.sendChannelMessage(existingChannels[0].Id, updateMessage);
        System.debug('✅ 기존 채널에 업데이트 메시지 게시 완료');
        
        return;
    }
    
    // 3. 새 채널 생성
    System.debug('=== 🏗️ 새 Salesforce 채널 생성 ===');
    
    String channelId = SimpleSalesforceChannelService.createOrderChannel(order156.Id);
    
    if(channelId != null) {
        System.debug('✅ 채널 생성 성공: ' + channelId);
        
        // 4. 멤버 추가
        System.debug('=== 👥 멤버 추가 ===');
        
        // Order Owner 추가
        Boolean ownerAdded = SimpleSalesforceChannelService.addUserToChannel(channelId, order156.OwnerId);
        System.debug('Order Owner 추가: ' + (ownerAdded ? '✅ 성공' : '❌ 실패'));
        
        // 현재 사용자 추가 (Order Owner와 다른 경우)
        if(UserInfo.getUserId() != order156.OwnerId) {
            Boolean currentUserAdded = SimpleSalesforceChannelService.addUserToChannel(channelId, UserInfo.getUserId());
            System.debug('현재 사용자 추가: ' + (currentUserAdded ? '✅ 성공' : '❌ 실패'));
        }
        
        // 5. 환영 메시지
        System.debug('=== 💬 환영 메시지 게시 ===');
        
        Boolean welcomePosted = SimpleSalesforceChannelService.postWelcomeMessage(channelId, order156.Id, order156.OrderNumber);
        System.debug('환영 메시지 게시: ' + (welcomePosted ? '✅ 성공' : '❌ 실패'));
        
        // 6. 추가 정보 메시지
        String infoMessage = '📊 Order 00000156 상세 정보\n\n';
        infoMessage += '🏢 Account: (주)그린파워텍\n';
        infoMessage += '💰 총 금액: ₩990,000\n';
        infoMessage += '📅 시작일: 2025-07-20\n';
        infoMessage += '📅 종료일: 2026-07-13\n';
        infoMessage += '💳 납부 방식: 분기별\n';
        infoMessage += '📋 계약 번호: 00000115\n';
        infoMessage += '⚡ 상태: Activated\n\n';
        infoMessage += '💡 이 채널에서 Order 관련 모든 소통과 협업을 진행하세요!\n';
        infoMessage += '🔔 Payment 알림도 이 채널에서 자동으로 수신됩니다.\n\n';
        infoMessage += '#Order정보 #팀협업 #자동화';
        
        SimpleSalesforceChannelService.sendChannelMessage(channelId, infoMessage);
        System.debug('✅ 추가 정보 메시지 게시 완료');
        
        // 7. 최종 결과
        System.debug('\n=== 🎉 Order 00000156 채널 생성 완료! ===');
        System.debug('채널 ID: ' + channelId);
        System.debug('채널명: Order-00000156');
        
        System.debug('\n=== 📱 Sales 앱에서 확인하기 ===');
        System.debug('1. Sales 앱 → Chatter → 그룹');
        System.debug('2. 검색: "Order-00000156" 또는 "00000156"');
        System.debug('3. 직접 URL: /lightning/r/CollaborationGroup/' + channelId + '/view');
        
        System.debug('\n=== 🔥 다음 단계 ===');
        System.debug('1. 팀원들을 채널에 초대');
        System.debug('2. @멘션으로 알림 테스트');
        System.debug('3. 파일 공유 기능 활용');
        System.debug('4. Payment 알림 자동 수신 확인');
        
    } else {
        System.debug('❌ 채널 생성 실패');
    }
    
} catch(Exception e) {
    System.debug('❌ 오류 발생: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

System.debug('\n=== ✅ Order 00000156 채널 생성 스크립트 완료 ===');

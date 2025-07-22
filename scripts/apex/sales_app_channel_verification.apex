/**
 * @description Sales 앱 Salesforce Channels 확인 실습 가이드
 * @author JH Moon
 * @created 2025-07-22
 */

System.debug('📱 =====Sales 앱 Salesforce Channels 확인 실습=====');

// 📋 실습 목표: Sales 앱에서 구현된 Salesforce Channels 기능 확인

// 1️⃣ Dashboard 확인 준비
System.debug('1️⃣ Payment Notification Dashboard 확인 준비');
System.debug('🔗 네비게이션: App Launcher → Payment Notification Dashboard');
System.debug('✅ 확인사항:');
System.debug('   • SalesforceChannel 통계 표시');
System.debug('   • 녹색 아이콘 (standard:groups)');
System.debug('   • 실시간 카운트 업데이트');

// 2️⃣ Order 레코드에서 채널 정보 확인
System.debug('');
System.debug('2️⃣ Order 레코드 채널 정보 확인');

List<Order> recentOrders = [
    SELECT Id, OrderNumber, Account.Name, Status, CreatedDate
    FROM Order 
    ORDER BY CreatedDate DESC 
    LIMIT 5
];

System.debug('📊 최근 Order 목록:');
for (Order order : recentOrders) {
    System.debug('   • ' + order.OrderNumber + ' (' + order.Account.Name + ') - ' + order.Status);
    System.debug('     🔗 확인 경로: Sales 앱 → Orders → ' + order.OrderNumber);
}

// 3️⃣ Chatter Groups 확인
System.debug('');
System.debug('3️⃣ Chatter Groups 채널 확인');

List<CollaborationGroup> orderChannels = [
    SELECT Id, Name, Description, MemberCount, CreatedDate
    FROM CollaborationGroup 
    WHERE Name LIKE 'Order-%'
    AND IsArchived = false
    ORDER BY CreatedDate DESC
    LIMIT 10
];

System.debug('💬 Order 관련 Chatter Groups:');
for (CollaborationGroup group : orderChannels) {
    System.debug('   • ' + group.Name + ' (멤버: ' + group.MemberCount + '명)');
    System.debug('     📅 생성일: ' + group.CreatedDate.format());
}

if (orderChannels.isEmpty()) {
    System.debug('⚠️ Order 채널이 없습니다. 새 Order를 생성하여 테스트해보세요.');
} else {
    System.debug('🔗 확인 경로: Chatter 탭 → Groups → 내 그룹');
}

// 4️⃣ Payment Notifications 확인
System.debug('');
System.debug('4️⃣ Payment Notifications 채널 사용 현황');

List<AggregateResult> channelStats = [
    SELECT NotificationChannel__c channel, COUNT(Id) cnt, 
           AVG(CASE WHEN NotificationStatus__c = 'Sent' THEN 1.0 ELSE 0.0 END) successRate
    FROM Payment_Notification__c 
    WHERE CreatedDate = LAST_N_DAYS:7
    GROUP BY NotificationChannel__c
];

System.debug('📈 최근 7일 알림 채널 통계:');
for (AggregateResult stat : channelStats) {
    String channel = (String)stat.get('channel');
    Integer count = (Integer)stat.get('cnt');
    Decimal successRate = (Decimal)stat.get('successRate');
    
    System.debug('   • ' + channel + ': ' + count + '건 (성공률: ' + 
                 (successRate * 100).setScale(1) + '%)');
}

// 5️⃣ 실시간 테스트 시나리오 안내
System.debug('');
System.debug('5️⃣ 실시간 테스트 시나리오');
System.debug('');

System.debug('📝 Order 생성 테스트:');
System.debug('1. Sales 앱에서 새 Order 생성');
System.debug('2. Account, Products, 담당자 설정');
System.debug('3. 저장 후 Chatter Groups 확인');
System.debug('4. 생성된 "Order-[번호]" 그룹 확인');
System.debug('5. 환영 메시지 자동 포스트 확인');

System.debug('');
System.debug('💰 Payment Notification 테스트:');
System.debug('1. PaymentStatus 레코드 생성');
System.debug('2. NotificationChannel__c = "SalesforceChannel" 설정');
System.debug('3. 배치 실행 또는 스케줄러 대기');
System.debug('4. 해당 Order 채널에서 알림 확인');

System.debug('');
System.debug('🤖 Order Product 자동화 테스트:');
System.debug('1. Order 상태를 "Activated"로 변경');
System.debug('2. 자동화 트리거 실행 대기');
System.debug('3. 채널에서 "자동화 완료" 메시지 확인');

// 6️⃣ Mobile 앱 확인 가이드
System.debug('');
System.debug('6️⃣ Mobile Sales 앱 확인');
System.debug('📱 Salesforce Mobile 앱에서:');
System.debug('   • Orders → 특정 Order → Chatter 확인');
System.debug('   • 푸시 알림 설정 확인');
System.debug('   • 채널 메시지 실시간 확인');
System.debug('   • @멘션 알림 테스트');

// 7️⃣ Dashboard 활용 팁
System.debug('');
System.debug('7️⃣ Dashboard 활용 팁');
System.debug('📊 Payment Notification Dashboard에서:');
System.debug('   • "Time Frame" 필터로 기간 조정');
System.debug('   • "Retry Failed Notifications" 버튼 활용');
System.debug('   • "Execute Batch Job" 수동 실행');
System.debug('   • "Scheduler Status" 상태 모니터링');

// 8️⃣ 문제 해결 체크리스트
System.debug('');
System.debug('8️⃣ 문제 해결 체크리스트');
System.debug('');

System.debug('❌ 채널이 생성되지 않는 경우:');
System.debug('   ✓ Order Owner가 설정되어 있는지 확인');
System.debug('   ✓ Account Owner가 활성 사용자인지 확인'); 
System.debug('   ✓ Developer Console에서 오류 로그 확인');
System.debug('   ✓ Chatter Groups 생성 권한 확인');

System.debug('');
System.debug('❌ 알림이 발송되지 않는 경우:');
System.debug('   ✓ PaymentStatus와 Payment_Notification 관계 확인');
System.debug('   ✓ NotificationChannel__c 값이 "SalesforceChannel"인지 확인');
System.debug('   ✓ 배치 작업 실행 상태 확인');
System.debug('   ✓ 채널 존재 여부 확인');

System.debug('');
System.debug('❌ Dashboard에서 통계가 표시되지 않는 경우:');
System.debug('   ✓ SalesforceChannel 데이터 존재 여부 확인');
System.debug('   ✓ Time Frame 설정 확인');
System.debug('   ✓ 브라우저 캐시 새로고침');
System.debug('   ✓ User Permission 확인');

// 9️⃣ 성공 지표 확인
System.debug('');
System.debug('9️⃣ 성공 지표 확인');

// 현재 시스템 상태 요약
Integer totalOrders = [SELECT COUNT() FROM Order WHERE CreatedDate = TODAY];
Integer totalChannels = [SELECT COUNT() FROM CollaborationGroup WHERE Name LIKE 'Order-%' AND CreatedDate = TODAY];
Integer totalNotifications = [SELECT COUNT() FROM Payment_Notification__c WHERE NotificationChannel__c = 'SalesforceChannel' AND CreatedDate = TODAY];

System.debug('📈 오늘의 성과:');
System.debug('   • 생성된 Order: ' + totalOrders + '개');
System.debug('   • 생성된 채널: ' + totalChannels + '개');
System.debug('   • SalesforceChannel 알림: ' + totalNotifications + '건');

if (totalChannels > 0) {
    System.debug('✅ Salesforce Channels 시스템이 정상 작동 중입니다!');
} else {
    System.debug('⚠️ 아직 채널이 생성되지 않았습니다. Order 생성을 통해 테스트해보세요.');
}

System.debug('');
System.debug('🎯 추천 다음 단계:');
System.debug('1. Sales 앱에서 실제 Order 생성하여 채널 확인');
System.debug('2. Payment Notification Dashboard에서 통계 모니터링');
System.debug('3. 팀원들과 채널 공유 및 협업 테스트');
System.debug('4. Mobile 앱에서 실시간 알림 확인');
System.debug('5. 정기적인 성능 리포트 작성');

System.debug('✅ =====Sales 앱 Salesforce Channels 확인 실습 완료=====');

// Sales 앱 알림을 위한 CustomNotificationType 설정 확인 및 생성 가이드
System.debug('🔔 =====Sales 앱 알림 CustomNotificationType 설정 확인=====');

try {
    // 1. 현재 설정된 CustomNotificationType 확인
    List<CustomNotificationType> existingTypes = [
        SELECT Id, DeveloperName, MasterLabel, Description
        FROM CustomNotificationType 
        ORDER BY DeveloperName
    ];
    
    System.debug('');
    System.debug('📋 현재 설정된 CustomNotificationType: ' + existingTypes.size() + '개');
    
    Boolean salesNotificationExists = false;
    Boolean paymentNotificationExists = false;
    
    for (CustomNotificationType type : existingTypes) {
        System.debug('   • ' + type.MasterLabel + ' (' + type.DeveloperName + ')');
        
        if (type.DeveloperName == 'Sales_Order_Notification') {
            salesNotificationExists = true;
        }
        if (type.DeveloperName == 'Payment_Notification') {
            paymentNotificationExists = true;
        }
    }
    
    // 2. 필수 CustomNotificationType 확인
    System.debug('');
    System.debug('✅ 필수 CustomNotificationType 확인:');
    
    if (salesNotificationExists) {
        System.debug('   ✅ Sales_Order_Notification: 설정됨');
    } else {
        System.debug('   ❌ Sales_Order_Notification: 설정 필요');
    }
    
    if (paymentNotificationExists) {
        System.debug('   ✅ Payment_Notification: 설정됨');
    } else {
        System.debug('   ❌ Payment_Notification: 설정 필요');
    }
    
    // 3. 생성이 필요한 경우 Setup 가이드 제공
    if (!salesNotificationExists || !paymentNotificationExists) {
        System.debug('');
        System.debug('🔧 =====CustomNotificationType 생성 가이드=====');
        System.debug('');
        System.debug('Setup에서 다음 단계를 따라 생성해주세요:');
        System.debug('1. Setup (⚙️) > Quick Find에서 "Custom Notifications" 검색');
        System.debug('2. Custom Notification Types 페이지로 이동');
        System.debug('3. "New" 버튼 클릭');
        System.debug('');
        
        if (!salesNotificationExists) {
            System.debug('📝 Sales_Order_Notification 생성:');
            System.debug('   - Custom Notification Type Name: Sales Order Notification');
            System.debug('   - API Name: Sales_Order_Notification');
            System.debug('   - Description: Order 생성, Slack 채널 생성, 연체 알림');
            System.debug('   - Notification Channel: Desktop and Mobile');
            System.debug('');
        }
        
        if (!paymentNotificationExists) {
            System.debug('📝 Payment_Notification 생성:');
            System.debug('   - Custom Notification Type Name: Payment Notification');
            System.debug('   - API Name: Payment_Notification');
            System.debug('   - Description: 납부 예정 및 연체 알림');
            System.debug('   - Notification Channel: Desktop and Mobile');
            System.debug('');
        }
        
        System.debug('4. Save 클릭');
        System.debug('5. 생성 후 이 스크립트를 다시 실행하여 확인');
    }
    
    // 4. 현재 사용자 정보 확인
    System.debug('');
    System.debug('👤 현재 사용자 정보:');
    
    User currentUser = [
        SELECT Id, Name, Email, ProfileId, Profile.Name, ManagerId, Manager.Name, Manager.Email
        FROM User 
        WHERE Id = :UserInfo.getUserId()
    ];
    
    System.debug('   사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
    System.debug('   Profile: ' + currentUser.Profile.Name);
    
    if (currentUser.ManagerId != null) {
        System.debug('   Manager: ' + currentUser.Manager.Name + ' (' + currentUser.Manager.Email + ')');
    } else {
        System.debug('   Manager: 없음');
    }
    
    // 5. 알림 수신 테스트 (설정이 완료된 경우)
    if (salesNotificationExists) {
        System.debug('');
        System.debug('🧪 알림 수신 테스트:');
        
        try {
            CustomNotificationType salesType = [
                SELECT Id FROM CustomNotificationType 
                WHERE DeveloperName = 'Sales_Order_Notification'
                LIMIT 1
            ];
            
            Set<String> recipients = new Set<String>();
            recipients.add(UserInfo.getUserId());
            
            if (currentUser.ManagerId != null) {
                recipients.add(currentUser.ManagerId);
            }
            
            Messaging.CustomNotification testNotification = new Messaging.CustomNotification();
            testNotification.setTitle('🧪 테스트 알림');
            testNotification.setBody('Sales 앱 알림 시스템 테스트입니다.');
            testNotification.setNotificationTypeId(salesType.Id);
            testNotification.send(recipients);
            
            System.debug('   ✅ 테스트 알림 발송 완료 (수신자: ' + recipients.size() + '명)');
            System.debug('   💡 상단 벨 아이콘을 확인해보세요!');
            
        } catch (Exception testEx) {
            System.debug('   ❌ 테스트 알림 발송 실패: ' + testEx.getMessage());
        }
    }
    
    // 6. 결론
    System.debug('');
    System.debug('📊 설정 상태 요약:');
    System.debug('   Sales Order 알림: ' + (salesNotificationExists ? '✅ 준비됨' : '❌ 설정 필요'));
    System.debug('   Payment 알림: ' + (paymentNotificationExists ? '✅ 준비됨' : '❌ 설정 필요'));
    
} catch (Exception e) {
    System.debug('❌ CustomNotificationType 확인 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
}

System.debug('');
System.debug('✅ =====CustomNotificationType 설정 확인 완료=====');

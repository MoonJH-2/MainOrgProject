// Sales 앱 알림용 CustomNotificationType 생성 가이드
System.debug('📋 =====Sales 앱 알림 CustomNotificationType 설정 가이드=====');
System.debug('');
System.debug('Order 관련 Sales 앱 상단 벨 아이콘 알림을 위해 CustomNotificationType이 필요합니다.');
System.debug('다음 단계를 따라 생성해주세요:');
System.debug('');
System.debug('🔧 Setup 단계:');
System.debug('1. Setup (⚙️) > Quick Find에서 "Custom Notifications" 검색');
System.debug('2. Custom Notification Types 페이지로 이동');
System.debug('3. "New" 버튼 클릭');
System.debug('4. 다음 정보 입력:');
System.debug('   - Custom Notification Type Name: Sales Order Notification');
System.debug('   - API Name: Sales_Order_Notification');
System.debug('   - Description: Order 생성, 연체, Slack 채널 관련 알림');
System.debug('   - Notification Channel: Desktop and Mobile');
System.debug('5. Save 클릭');
System.debug('');

// 현재 CustomNotificationType 상태 확인
System.debug('🎯 현재 상태 확인:');

List<CustomNotificationType> existingOrderTypes = [
    SELECT Id, DeveloperName, MasterLabel, Description
    FROM CustomNotificationType 
    WHERE DeveloperName = 'Sales_Order_Notification'
];

List<CustomNotificationType> existingPaymentTypes = [
    SELECT Id, DeveloperName, MasterLabel, Description
    FROM CustomNotificationType 
    WHERE DeveloperName = 'Payment_Notification'
];

if (existingOrderTypes.isEmpty()) {
    System.debug('❌ Sales_Order_Notification이 아직 생성되지 않았습니다.');
    System.debug('   위의 Setup 단계를 완료한 후 다시 테스트해주세요.');
} else {
    System.debug('✅ Sales_Order_Notification이 이미 생성되어 있습니다:');
    for (CustomNotificationType type : existingOrderTypes) {
        System.debug('   • ID: ' + type.Id);
        System.debug('   • Name: ' + type.MasterLabel + ' (' + type.DeveloperName + ')');
        System.debug('   • Description: ' + type.Description);
    }
}

if (existingPaymentTypes.isEmpty()) {
    System.debug('⚠️ Payment_Notification도 생성이 필요합니다.');
    System.debug('   같은 방식으로 Payment_Notification도 생성해주세요.');
} else {
    System.debug('✅ Payment_Notification이 이미 생성되어 있습니다.');
}

System.debug('');
System.debug('📱 사용자 설정 확인:');
System.debug('• 사용자는 알림을 받으려면 브라우저에서 알림 권한을 허용해야 합니다.');
System.debug('• Lightning Experience에서만 작동합니다.');
System.debug('• Mobile Salesforce 앱에서도 푸시 알림으로 받을 수 있습니다.');

// 현재 사용자 정보
User currentUser = [SELECT Id, Name, Email, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('');
System.debug('👤 현재 사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
System.debug('👤 프로필: ' + currentUser.Profile.Name);

System.debug('');
System.debug('✅ =====CustomNotificationType 설정 가이드 완료=====');

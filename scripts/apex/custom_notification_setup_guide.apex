// Custom Notification Type 생성 가이드
// Setup에서 수동 생성이 필요한 Custom Notification Type 설정 안내

System.debug('📋 =====Custom Notification Type 생성 가이드=====');
System.debug('');
System.debug('Salesforce 상단 벨 아이콘 알림을 위해서는 Custom Notification Type이 필요합니다.');
System.debug('다음 단계를 따라 생성해주세요:');
System.debug('');
System.debug('🔧 Setup 단계:');
System.debug('1. Setup (⚙️) > Quick Find에서 "Custom Notifications" 검색');
System.debug('2. Custom Notification Types 페이지로 이동');
System.debug('3. "New" 버튼 클릭');
System.debug('4. 다음 정보 입력:');
System.debug('   - Custom Notification Type Name: Payment Notification');
System.debug('   - API Name: Payment_Notification');
System.debug('   - Description: 납부 관련 알림 (Payment-related notifications)');
System.debug('   - Notification Channel: Desktop and Mobile');
System.debug('5. Save 클릭');
System.debug('');
System.debug('🎯 확인 방법:');

// 현재 CustomNotificationType 상태 확인
List<CustomNotificationType> existingTypes = [
    SELECT Id, DeveloperName, MasterLabel, Description
    FROM CustomNotificationType 
    WHERE DeveloperName = 'Payment_Notification'
];

if (existingTypes.isEmpty()) {
    System.debug('❌ Custom Notification Type이 아직 생성되지 않았습니다.');
    System.debug('   위의 Setup 단계를 완료한 후 다시 테스트해주세요.');
} else {
    System.debug('✅ Custom Notification Type이 이미 생성되어 있습니다:');
    for (CustomNotificationType type : existingTypes) {
        System.debug('   • ID: ' + type.Id);
        System.debug('   • Name: ' + type.MasterLabel + ' (' + type.DeveloperName + ')');
        System.debug('   • Description: ' + type.Description);
    }
}

System.debug('');
System.debug('💡 추가 정보:');
System.debug('• Custom Notification은 Lightning Experience에서만 작동합니다.');
System.debug('• 사용자는 알림을 받으려면 브라우저에서 알림 권한을 허용해야 합니다.');
System.debug('• Mobile Salesforce 앱에서도 푸시 알림으로 받을 수 있습니다.');
System.debug('');

// 현재 사용자의 알림 설정 확인
User currentUser = [SELECT Id, Name, Email, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('👤 현재 사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
System.debug('👤 프로필: ' + currentUser.Profile.Name);

System.debug('');
System.debug('🔔 =====Custom Notification Type 생성 가이드 완료=====');

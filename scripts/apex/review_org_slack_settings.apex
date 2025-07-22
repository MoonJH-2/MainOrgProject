// Salesforce Org 내 Slack 연동 설정 검토 스크립트
// Order 00000158 Slack Channel 활성화를 위한 조직 레벨 설정 분석

try {
    System.debug('=== Salesforce Org Slack 연동 설정 검토 ===');
    
    // 1. Order 00000158 현재 상태 재확인
    List<Order> orders = [
        SELECT Id, OrderNumber, Slack_Channel_ID__c, Slack_Channel_Name__c, 
               Slack_Notification_Status__c, Slack_Webhook_URL__c
        FROM Order 
        WHERE OrderNumber = '00000158'
        LIMIT 1
    ];
    
    if (!orders.isEmpty()) {
        Order order = orders[0];
        System.debug('📋 Order 00000158 현재 상태:');
        System.debug('- Slack Channel ID: ' + order.Slack_Channel_ID__c);
        System.debug('- Slack Channel Name: ' + order.Slack_Channel_Name__c);
        System.debug('- Slack Notification Status: ' + order.Slack_Notification_Status__c);
        System.debug('- Slack Webhook URL: ' + order.Slack_Webhook_URL__c);
    }
    
    // 2. Slack 관련 Custom Setting 확인
    System.debug('\n=== Custom Settings 확인 ===');
    
    // 가능한 Slack 설정들 확인
    try {
        // Organization-wide Default 설정이 있는지 확인
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        List<String> possibleSlackSettings = new List<String>{
            'SlackSettings__c',
            'Slack_Configuration__c', 
            'Integration_Settings__c',
            'Channel_Settings__c'
        };
        
        for (String settingName : possibleSlackSettings) {
            if (globalDescribe.containsKey(settingName)) {
                System.debug('✅ 발견된 Custom Setting: ' + settingName);
            } else {
                System.debug('❌ 존재하지 않는 설정: ' + settingName);
            }
        }
        
    } catch (Exception e) {
        System.debug('Custom Settings 확인 중 오류: ' + e.getMessage());
    }
    
    // 3. Slack App 연결 상태 확인
    System.debug('\n=== Slack App 연결 상태 확인 ===');
    
    // ConnectedApplication 확인 (Slack App)
    List<ConnectedApplication> slackApps = [
        SELECT Id, Name, CreatedDate, LastModifiedDate
        FROM ConnectedApplication 
        WHERE Name LIKE '%Slack%' 
        OR Name LIKE '%slack%'
        LIMIT 5
    ];
    
    if (slackApps.isEmpty()) {
        System.debug('❌ Slack Connected Application이 설치되지 않음');
        System.debug('💡 해결책: AppExchange에서 Slack for Salesforce 설치 필요');
    } else {
        System.debug('✅ Slack Connected Applications 발견: ' + slackApps.size() + '개');
        for (ConnectedApplication app : slackApps) {
            System.debug('- App Name: ' + app.Name);
            System.debug('- Created: ' + app.CreatedDate);
        }
    }
    
    // 4. Permission Set 확인
    System.debug('\n=== Permission Set 확인 ===');
    
    List<PermissionSet> slackPermSets = [
        SELECT Id, Name, Label, Description
        FROM PermissionSet 
        WHERE Name LIKE '%Slack%' 
        OR Label LIKE '%Slack%'
        OR Description LIKE '%Slack%'
        LIMIT 5
    ];
    
    if (slackPermSets.isEmpty()) {
        System.debug('❌ Slack 관련 Permission Set 없음');
        System.debug('💡 해결책: Slack 관련 권한 설정 필요');
    } else {
        System.debug('✅ Slack Permission Sets 발견: ' + slackPermSets.size() + '개');
        for (PermissionSet ps : slackPermSets) {
            System.debug('- Permission Set: ' + ps.Name + ' (' + ps.Label + ')');
        }
    }
    
    // 5. Current User의 Slack 권한 확인
    System.debug('\n=== 현재 사용자 Slack 권한 확인 ===');
    
    User currentUser = [
        SELECT Id, Name, Profile.Name, UserPermissionsSlackUser
        FROM User 
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];
    
    System.debug('현재 사용자: ' + currentUser.Name);
    System.debug('프로필: ' + currentUser.Profile.Name);
    System.debug('Slack User 권한: ' + currentUser.UserPermissionsSlackUser);
    
    if (!currentUser.UserPermissionsSlackUser) {
        System.debug('❌ 현재 사용자에게 Slack User 권한 없음');
        System.debug('💡 해결책: 사용자 프로필 또는 Permission Set에서 Slack 권한 활성화 필요');
    }
    
    // 6. Chatter 설정 확인
    System.debug('\n=== Chatter 설정 확인 ===');
    
    Organization orgInfo = [
        SELECT Id, IsSandbox, InstanceName, OrganizationType
        FROM Organization
        LIMIT 1
    ];
    
    System.debug('조직 유형: ' + orgInfo.OrganizationType);
    System.debug('Sandbox 여부: ' + orgInfo.IsSandbox);
    System.debug('인스턴스: ' + orgInfo.InstanceName);
    
    // 7. 필수 설정 검토 결과
    System.debug('\n=== 필수 설정 검토 결과 ===');
    
    List<String> requiredActions = new List<String>();
    
    if (slackApps.isEmpty()) {
        requiredActions.add('1. AppExchange에서 "Slack for Salesforce" 앱 설치');
    }
    
    if (!currentUser.UserPermissionsSlackUser) {
        requiredActions.add('2. 사용자 프로필에서 "Slack User" 권한 활성화');
    }
    
    if (slackPermSets.isEmpty()) {
        requiredActions.add('3. Slack 관련 Permission Set 할당');
    }
    
    // Webhook URL이 비어있는 경우
    if (!orders.isEmpty() && String.isBlank(orders[0].Slack_Webhook_URL__c)) {
        requiredActions.add('4. Order에 Slack Webhook URL 설정');
    }
    
    if (requiredActions.isEmpty()) {
        System.debug('✅ 모든 필수 설정이 완료되었습니다!');
        System.debug('💡 Order의 Slack_Notification_Status__c만 "Created"로 업데이트하면 됩니다.');
    } else {
        System.debug('🔧 다음 설정이 필요합니다:');
        for (String action : requiredActions) {
            System.debug('   ' + action);
        }
    }
    
} catch (Exception e) {
    System.debug('❌ 설정 검토 중 오류: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}

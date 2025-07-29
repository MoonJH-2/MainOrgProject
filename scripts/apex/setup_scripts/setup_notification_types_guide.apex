// CustomNotificationType 설정 완전 가이드 및 테스트 스크립트
System.debug('🔔 =====CustomNotificationType 설정 완전 가이드=====');

try {
    System.debug('');
    System.debug('📋 현재 설정 상태 확인 중...');
    
    // 1. 현재 설정된 모든 CustomNotificationType 조회
    List<CustomNotificationType> allTypes = [
        SELECT Id, DeveloperName, MasterLabel, Description, 
               Desktop, Mobile, CreatedDate, CreatedBy.Name
        FROM CustomNotificationType 
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('');
    System.debug('📊 전체 CustomNotificationType 수: ' + allTypes.size() + '개');
    
    Boolean salesOrderExists = false;
    Boolean paymentNotificationExists = false;
    CustomNotificationType salesOrderType = null;
    CustomNotificationType paymentType = null;
    
    // 기존 설정 확인
    for (CustomNotificationType type : allTypes) {
        System.debug('   • ' + type.MasterLabel + ' (' + type.DeveloperName + ')');
        System.debug('     - Desktop: ' + type.Desktop + ', Mobile: ' + type.Mobile);
        System.debug('     - 생성일: ' + type.CreatedDate.format('yyyy-MM-dd HH:mm') + ' by ' + type.CreatedBy.Name);
        
        if (type.DeveloperName == 'Sales_Order_Notification') {
            salesOrderExists = true;
            salesOrderType = type;
        }
        if (type.DeveloperName == 'Payment_Notification') {
            paymentNotificationExists = true;
            paymentType = type;
        }
        System.debug('');
    }
    
    // 2. 필수 설정 상태 확인
    System.debug('🎯 필수 설정 상태:');
    System.debug('');
    
    if (salesOrderExists) {
        System.debug('   ✅ Sales_Order_Notification: 설정 완료');
        System.debug('      - ID: ' + salesOrderType.Id);
        System.debug('      - Label: ' + salesOrderType.MasterLabel);
        System.debug('      - Desktop 알림: ' + salesOrderType.Desktop);
        System.debug('      - Mobile 알림: ' + salesOrderType.Mobile);
        System.debug('      - Description: ' + salesOrderType.Description);
    } else {
        System.debug('   ❌ Sales_Order_Notification: 설정 필요');
    }
    
    System.debug('');
    
    if (paymentNotificationExists) {
        System.debug('   ✅ Payment_Notification: 설정 완료 (선택사항)');
        System.debug('      - ID: ' + paymentType.Id);
        System.debug('      - Label: ' + paymentType.MasterLabel);
        System.debug('      - Desktop 알림: ' + paymentType.Desktop);
        System.debug('      - Mobile 알림: ' + paymentType.Mobile);
    } else {
        System.debug('   ⚠️ Payment_Notification: 미설정 (선택사항)');
    }
    
    // 3. 설정이 필요한 경우 상세 가이드 제공
    if (!salesOrderExists || !paymentNotificationExists) {
        System.debug('');
        System.debug('🔧 =====CustomNotificationType 생성 가이드=====');
        System.debug('');
        System.debug('다음 단계를 따라 Salesforce Setup에서 생성해주세요:');
        System.debug('');
        System.debug('1️⃣ Setup 접근:');
        System.debug('   • Salesforce 우상단 ⚙️ Setup 클릭');
        System.debug('   • Quick Find에서 "Custom Notifications" 검색');
        System.debug('   • "Custom Notification Types" 선택');
        System.debug('');
        
        if (!salesOrderExists) {
            System.debug('2️⃣ Sales_Order_Notification 생성 (필수):');
            System.debug('   • "New" 버튼 클릭');
            System.debug('   • Custom Notification Type Name: Sales Order Notification');
            System.debug('   • API Name: Sales_Order_Notification');
            System.debug('   • Description: Order 생성, Slack 채널 생성, 연체 알림을 위한 Sales 앱 알림');
            System.debug('   • Desktop: ✅ 체크');
            System.debug('   • Mobile: ✅ 체크');
            System.debug('   • "Save" 클릭');
            System.debug('');
        }
        
        if (!paymentNotificationExists) {
            System.debug('3️⃣ Payment_Notification 생성 (선택사항):');
            System.debug('   • "New" 버튼 클릭');
            System.debug('   • Custom Notification Type Name: Payment Notification');
            System.debug('   • API Name: Payment_Notification');
            System.debug('   • Description: 납부 예정 및 연체 알림을 위한 상세 알림');
            System.debug('   • Desktop: ✅ 체크');
            System.debug('   • Mobile: ✅ 체크');
            System.debug('   • "Save" 클릭');
            System.debug('');
        }
        
        System.debug('4️⃣ 생성 완료 후:');
        System.debug('   • 이 스크립트를 다시 실행하여 설정 확인');
        System.debug('   • 브라우저에서 Salesforce 알림 권한 허용');
        System.debug('   • Lightning Experience 사용 (Classic 불가)');
        System.debug('');
    }
    
    // 4. 현재 사용자 및 환경 정보
    System.debug('👤 현재 사용자 및 환경 정보:');
    
    User currentUser = [
        SELECT Id, Name, Email, ProfileId, Profile.Name, 
               ManagerId, Manager.Name, Manager.Email, IsActive
        FROM User 
        WHERE Id = :UserInfo.getUserId()
    ];
    
    System.debug('   사용자: ' + currentUser.Name + ' (' + currentUser.Email + ')');
    System.debug('   Profile: ' + currentUser.Profile.Name);
    System.debug('   활성 상태: ' + currentUser.IsActive);
    
    if (currentUser.ManagerId != null) {
        System.debug('   Manager: ' + currentUser.Manager.Name + ' (' + currentUser.Manager.Email + ')');
    } else {
        System.debug('   Manager: 없음');
    }
    
    System.debug('   조직 ID: ' + UserInfo.getOrganizationId());
    System.debug('   사용자 ID: ' + UserInfo.getUserId());
    
    // 5. 알림 테스트 (설정이 완료된 경우)
    if (salesOrderExists) {
        System.debug('');
        System.debug('🧪 Sales Order 알림 테스트:');
        
        try {
            Set<String> recipients = new Set<String>();
            recipients.add(UserInfo.getUserId());
            
            // Manager가 있으면 추가
            if (currentUser.ManagerId != null) {
                recipients.add(currentUser.ManagerId);
            }
            
            Messaging.CustomNotification testNotification = new Messaging.CustomNotification();
            testNotification.setTitle('🧪 Sales Order 알림 테스트');
            testNotification.setBody('CustomNotificationType 설정이 정상적으로 완료되었습니다!');
            testNotification.setNotificationTypeId(salesOrderType.Id);
            testNotification.send(recipients);
            
            System.debug('   ✅ 테스트 알림 발송 완료');
            System.debug('   💡 Salesforce 상단 🔔 벨 아이콘을 확인해보세요!');
            System.debug('   📱 Mobile 앱에서도 푸시 알림이 도착합니다.');
            
        } catch (Exception testEx) {
            System.debug('   ❌ 테스트 알림 발송 실패: ' + testEx.getMessage());
            System.debug('   💡 브라우저 알림 권한을 확인해주세요.');
        }
    }
    
    if (paymentNotificationExists) {
        System.debug('');
        System.debug('🧪 Payment 알림 테스트:');
        
        try {
            Set<String> recipients = new Set<String>();
            recipients.add(UserInfo.getUserId());
            
            Messaging.CustomNotification paymentTestNotification = new Messaging.CustomNotification();
            paymentTestNotification.setTitle('💰 Payment 알림 테스트');
            paymentTestNotification.setBody('납부 알림 시스템이 준비되었습니다.');
            paymentTestNotification.setNotificationTypeId(paymentType.Id);
            paymentTestNotification.send(recipients);
            
            System.debug('   ✅ Payment 테스트 알림 발송 완료');
            
        } catch (Exception paymentTestEx) {
            System.debug('   ❌ Payment 테스트 알림 발송 실패: ' + paymentTestEx.getMessage());
        }
    }
    
    // 6. 브라우저 설정 가이드
    System.debug('');
    System.debug('🌐 브라우저 설정 확인:');
    System.debug('   Chrome: 주소창 왼쪽 🔒 아이콘 > 알림 > 허용');
    System.debug('   Firefox: 주소창 왼쪽 아이콘 > 알림 권한 > 허용');
    System.debug('   Safari: 환경설정 > 웹사이트 > 알림 > Salesforce 허용');
    
    // 7. 최종 상태 요약
    System.debug('');
    System.debug('📊 =====설정 완료 상태 요약=====');
    
    Integer completedCount = 0;
    if (salesOrderExists) completedCount++;
    if (paymentNotificationExists) completedCount++;
    
    System.debug('   설정 완료: ' + completedCount + '/2');
    System.debug('   Sales Order 알림: ' + (salesOrderExists ? '✅ 완료' : '❌ 필요'));
    System.debug('   Payment 알림: ' + (paymentNotificationExists ? '✅ 완료' : '⚠️ 선택사항'));
    
    if (salesOrderExists) {
        System.debug('');
        System.debug('🎉 Order 00000149 알림 시스템 준비 완료!');
        System.debug('   • Order 생성 알림: 준비됨');
        System.debug('   • Slack 채널 생성 알림: 준비됨');
        System.debug('   • 연체 알림: 준비됨');
        System.debug('');
        System.debug('다음 스크립트로 전체 시스템을 테스트해보세요:');
        System.debug('sfdx force:apex:execute -f scripts/apex/review_order_149_notifications.apex');
    } else {
        System.debug('');
        System.debug('⚠️ 아직 설정이 완료되지 않았습니다.');
        System.debug('   위의 가이드를 따라 CustomNotificationType을 생성해주세요.');
    }
    
} catch (Exception e) {
    System.debug('❌ CustomNotificationType 확인 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
    System.debug('   스택: ' + e.getStackTraceString());
}

System.debug('');
System.debug('✅ =====CustomNotificationType 설정 가이드 완료=====');

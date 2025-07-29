// 전체 알림 시스템 종합 테스트 스크립트
// 실제 메일 발송, Custom Notification, PDF 첨부 등 모든 기능 테스트

System.debug('🚀 =====전체 알림 시스템 종합 테스트 시작=====');

try {
    // 1. 연체된 PaymentStatus 조회
    List<PaymentStatus__c> overduePayments = [
        SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber, 
               InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Status__c != '완납' 
        AND DueDate__c < TODAY
        ORDER BY DueDate__c ASC
        LIMIT 3
    ];
    
    System.debug('📊 연체 납부 현황: ' + overduePayments.size() + '건');
    
    if (overduePayments.isEmpty()) {
        System.debug('❌ 테스트할 연체 데이터가 없습니다.');
        return;
    }
    
    // 2. Custom Notification Type 확인/생성
    List<CustomNotificationType> notificationTypes = [
        SELECT Id, DeveloperName FROM CustomNotificationType 
        WHERE DeveloperName = 'Payment_Notification'
    ];
    
    if (notificationTypes.isEmpty()) {
        System.debug('⚠️ CustomNotificationType "Payment_Notification"이 없습니다.');
        System.debug('💡 Setup > Custom Notifications에서 다음과 같이 생성해주세요:');
        System.debug('   - Label: Payment Notification');
        System.debug('   - Name: Payment_Notification');
        System.debug('   - Description: 납부 관련 알림');
    } else {
        System.debug('✅ CustomNotificationType 확인됨: ' + notificationTypes[0].Id);
    }
    
    // 3. 각 연체 건에 대해 종합 알림 테스트
    List<Payment_Notification__c> testNotifications = new List<Payment_Notification__c>();
    
    for (PaymentStatus__c payment : overduePayments) {
        Payment_Notification__c notification = new Payment_Notification__c();
        notification.PaymentStatus__c = payment.Id;
        notification.NotificationType__c = '연체 알림';
        notification.NotificationChannel__c = 'Salesforce'; // 일단 Salesforce만 테스트
        notification.NotificationStatus__c = 'Pending';
        notification.ScheduledDateTime__c = DateTime.now();
        // notification.RecipientEmail__c = 'test@example.com'; // 필드 확인 후 추가
        
        testNotifications.add(notification);
    }
    
    insert testNotifications;
    System.debug('✅ 테스트 알림 레코드 생성 완료: ' + testNotifications.size() + '건');
    
    // 4. 각 채널별 알림 발송 테스트
    for (Payment_Notification__c notification : testNotifications) {
        // 관계 필드 재조회
        Payment_Notification__c fullNotification = [
            SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
                   PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.Account.Id,
                   PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c,
                   PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c,
                   NotificationType__c, NotificationChannel__c
            FROM Payment_Notification__c 
            WHERE Id = :notification.Id
        ];
        
        System.debug('📧 테스트 대상: ' + fullNotification.PaymentStatus__r.Order__r.Account.Name + 
                    ' ' + fullNotification.PaymentStatus__r.InstallmentNumber__c + '차');
        
        // 4-1. Salesforce 내부 알림 테스트
        System.debug('🔔 Salesforce 알림 테스트 중...');
        Boolean salesforceResult = PaymentNotificationService.sendSalesforceNotification(fullNotification);
        System.debug('   결과: ' + (salesforceResult ? '✅ 성공' : '❌ 실패'));
        
        // 4-2. 이메일 알림 테스트
        System.debug('📧 이메일 알림 테스트 중...');
        Boolean emailResult = PaymentNotificationService.sendEmailNotification(fullNotification);
        System.debug('   결과: ' + (emailResult ? '✅ 성공' : '❌ 실패'));
        
        // 4-3. 슬랙 알림 테스트 (옵션)
        System.debug('💬 슬랙 알림 테스트 중...');
        Boolean slackResult = PaymentNotificationService.sendSlackNotification(fullNotification);
        System.debug('   결과: ' + (slackResult ? '✅ 성공' : '❌ 실패'));
        
        System.debug('---');
    }
    
    // 5. Order 페이지에서 생성된 Task 확인
    System.debug('📋 생성된 Task 확인 중...');
    
    // Order ID 수집
    Set<Id> orderIds = new Set<Id>();
    for (Payment_Notification__c notif : testNotifications) {
        // 관계 필드를 다시 쿼리
        Payment_Notification__c temp = [
            SELECT PaymentStatus__r.Order__c 
            FROM Payment_Notification__c 
            WHERE Id = :notif.Id
        ];
        orderIds.add(temp.PaymentStatus__r.Order__c);
    }
    
    List<Task> createdTasks = [
        SELECT Id, Subject, WhatId, Priority, Status, ActivityDate, Description
        FROM Task 
        WHERE WhatId IN :orderIds
        AND CreatedDate = TODAY
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('📝 생성된 Task 수: ' + createdTasks.size() + '개');
    for (Task task : createdTasks) {
        System.debug('   • ' + task.Subject + ' (Order ID: ' + task.WhatId + ', 우선순위: ' + task.Priority + ')');
    }
    
    // 6. 생성된 Chatter 포스트 확인
    System.debug('💬 생성된 Chatter 포스트 확인 중...');
    List<FeedItem> chatterPosts = [
        SELECT Id, Body, ParentId, CreatedDate
        FROM FeedItem 
        WHERE ParentId IN :orderIds
        AND CreatedDate = TODAY
        ORDER BY CreatedDate DESC
    ];
    
    System.debug('📄 생성된 Chatter 포스트 수: ' + chatterPosts.size() + '개');
    for (FeedItem post : chatterPosts) {
        System.debug('   • Order ID: ' + post.ParentId + ' - ' + post.Body.substring(0, Math.min(50, post.Body.length())) + '...');
    }
    
    // 7. Notes & Attachments PDF 파일 확인
    System.debug('📎 PDF 첨부파일 확인 중...');
    List<ContentDocumentLink> pdfFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, LinkedEntityId
        FROM ContentDocumentLink 
        WHERE LinkedEntityId IN :orderIds
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('📁 발견된 PDF 파일 수: ' + pdfFiles.size() + '개');
    for (ContentDocumentLink pdf : pdfFiles) {
        System.debug('   • ' + pdf.ContentDocument.Title + '.pdf (Order ID: ' + pdf.LinkedEntityId + ')');
    }
    
    // 8. 테스트 결과 요약
    System.debug('');
    System.debug('📊 =====테스트 결과 요약=====');
    System.debug('• 테스트 알림 수: ' + testNotifications.size() + '건');
    System.debug('• 생성된 Task: ' + createdTasks.size() + '개');
    System.debug('• 생성된 Chatter 포스트: ' + chatterPosts.size() + '개');
    System.debug('• 사용 가능한 PDF 파일: ' + pdfFiles.size() + '개');
    System.debug('• CustomNotificationType 상태: ' + (notificationTypes.isEmpty() ? '❌ 미생성' : '✅ 생성됨'));
    
    System.debug('');
    System.debug('🎯 확인사항:');
    System.debug('1. Order 페이지 Activity Timeline에서 Task 확인');
    System.debug('2. Salesforce 상단 벨 아이콘에서 알림 확인');
    System.debug('3. 이메일 수신함에서 고객/관리자 메일 확인');
    System.debug('4. Order Chatter에서 자동 포스트 확인');
    
    System.debug('✅ =====전체 알림 시스템 종합 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ 테스트 중 오류 발생: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// Order 00000115 전용 테스트
System.debug('🎯 =====Order 00000115 전용 테스트 시작=====');

try {
    // 1. Order 00000115 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name, Account.Id, Owner.Name, Owner.Email, Status
        FROM Order 
        WHERE OrderNumber = '00000115'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000115를 찾을 수 없습니다.');
        return;
    }
    
    Order targetOrder = orders[0];
    System.debug('📋 Order 정보:');
    System.debug('   • Order Number: ' + targetOrder.OrderNumber);
    System.debug('   • Account: ' + targetOrder.Account.Name);
    System.debug('   • Owner: ' + targetOrder.Owner.Name + ' (' + targetOrder.Owner.Email + ')');
    System.debug('   • Status: ' + targetOrder.Status);
    System.debug('   • Order ID: ' + targetOrder.Id);
    
    // 2. 해당 Order의 PaymentStatus 조회
    List<PaymentStatus__c> paymentStatuses = [
        SELECT Id, Order__c, InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('💰 PaymentStatus 현황: ' + paymentStatuses.size() + '건');
    for (PaymentStatus__c payment : paymentStatuses) {
        Boolean isOverdue = payment.DueDate__c < Date.today() && payment.Status__c != '완납';
        String status = isOverdue ? '🔴 연체' : (payment.Status__c == '완납' ? '✅ 완납' : '⏳ 예정');
        System.debug('   • ' + payment.InstallmentNumber__c + '차: ₩' + payment.Amount__c.format() + 
                     ' (예정일: ' + payment.DueDate__c.format() + ') ' + status);
    }
    
    // 3. 연체된 PaymentStatus 찾기
    List<PaymentStatus__c> overduePayments = new List<PaymentStatus__c>();
    for (PaymentStatus__c payment : paymentStatuses) {
        if (payment.DueDate__c < Date.today() && payment.Status__c != '완납') {
            overduePayments.add(payment);
        }
    }
    
    System.debug('🚨 연체 건수: ' + overduePayments.size() + '건');
    
    if (overduePayments.isEmpty()) {
        System.debug('   모든 납부가 정상 상태입니다.');
    } else {
        // 4. 연체 건에 대한 알림 레코드 생성 및 테스트
        for (PaymentStatus__c overduePayment : overduePayments) {
            System.debug('🚨 연체 처리 중: ' + overduePayment.InstallmentNumber__c + '차');
            
            // Payment_Notification__c 레코드 생성
            Payment_Notification__c notification = new Payment_Notification__c();
            notification.PaymentStatus__c = overduePayment.Id;
            notification.NotificationType__c = '연체 알림';
            notification.NotificationChannel__c = 'Salesforce';
            notification.NotificationStatus__c = 'Pending';
            notification.ScheduledDateTime__c = DateTime.now();
            
            insert notification;
            System.debug('   ✅ 알림 레코드 생성: ' + notification.Id);
            
            // 관계 필드와 함께 다시 조회
            Payment_Notification__c fullNotification = [
                SELECT Id, PaymentStatus__c, PaymentStatus__r.Order__c,
                       PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.Account.Id,
                       PaymentStatus__r.Order__r.OrderNumber, PaymentStatus__r.InstallmentNumber__c,
                       PaymentStatus__r.Amount__c, PaymentStatus__r.DueDate__c, PaymentStatus__r.Status__c,
                       NotificationType__c, NotificationChannel__c
                FROM Payment_Notification__c 
                WHERE Id = :notification.Id
            ];
            
            // Salesforce 알림 발송
            System.debug('   🔔 알림 발송 중...');
            Boolean result = PaymentNotificationService.sendSalesforceNotification(fullNotification);
            System.debug('   📊 발송 결과: ' + (result ? '✅ 성공' : '❌ 실패'));
        }
    }
    
    // 5. Order 00000115에 연결된 모든 Task 조회
    System.debug('📝 Order 00000115 연결 Task 조회:');
    List<Task> relatedTasks = [
        SELECT Id, Subject, Priority, Status, ActivityDate, CreatedDate, Description
        FROM Task 
        WHERE WhatId = :targetOrder.Id
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
    
    System.debug('   총 Task 수: ' + relatedTasks.size() + '개');
    for (Task task : relatedTasks) {
        String createdToday = task.CreatedDate.date() == Date.today() ? ' [오늘 생성]' : '';
        System.debug('   • ' + task.Subject + ' (' + task.Priority + ', ' + task.Status + ')' + createdToday);
        System.debug('     활동일: ' + (task.ActivityDate != null ? task.ActivityDate.format() : '미설정'));
    }
    
    // 6. Chatter 포스트 확인
    System.debug('💬 Order 00000115 Chatter 포스트:');
    List<FeedItem> chatterPosts = [
        SELECT Id, Body, CreatedDate, CreatedBy.Name
        FROM FeedItem 
        WHERE ParentId = :targetOrder.Id
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    System.debug('   총 Chatter 포스트: ' + chatterPosts.size() + '개');
    for (FeedItem post : chatterPosts) {
        String createdToday = post.CreatedDate.date() == Date.today() ? ' [오늘]' : '';
        System.debug('   • ' + post.CreatedBy.Name + ': ' + 
                     post.Body.substring(0, Math.min(50, post.Body.length())) + '...' + createdToday);
    }
    
    // 7. PDF 파일 확인
    System.debug('📎 Order 00000115 첨부 파일:');
    List<ContentDocumentLink> attachments = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, 
               ContentDocument.CreatedDate
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        ORDER BY ContentDocument.CreatedDate DESC
        LIMIT 5
    ];
    
    System.debug('   총 첨부 파일: ' + attachments.size() + '개');
    for (ContentDocumentLink attachment : attachments) {
        System.debug('   • ' + attachment.ContentDocument.Title + 
                     '.' + attachment.ContentDocument.FileExtension +
                     ' (생성일: ' + attachment.ContentDocument.CreatedDate.format() + ')');
    }
    
    // 8. 고객 정보 확인
    System.debug('👤 고객 정보:');
    List<Contact> customerContacts = [
        SELECT Id, Name, Email, Phone
        FROM Contact 
        WHERE AccountId = :targetOrder.Account.Id
        ORDER BY CreatedDate ASC
        LIMIT 3
    ];
    
    System.debug('   연관된 연락처: ' + customerContacts.size() + '개');
    for (Contact contact : customerContacts) {
        System.debug('   • ' + contact.Name + ' (' + contact.Email + ', ' + contact.Phone + ')');
    }
    
    // 9. 테스트 결과 요약
    System.debug('');
    System.debug('📊 =====Order 00000115 테스트 결과 요약=====');
    System.debug('• Order 상태: ✅ ' + targetOrder.Status);
    System.debug('• PaymentStatus: ' + paymentStatuses.size() + '건 (연체: ' + overduePayments.size() + '건)');
    System.debug('• 생성된 Task: ' + relatedTasks.size() + '개');
    System.debug('• Chatter 포스트: ' + chatterPosts.size() + '개');
    System.debug('• 첨부 파일: ' + attachments.size() + '개');
    System.debug('• 고객 연락처: ' + customerContacts.size() + '개');
    
    // 10. Activity Timeline 확인 안내
    System.debug('');
    System.debug('🎯 확인해야 할 사항:');
    System.debug('1. Order 00000115 페이지의 Activity Timeline에서 Task 확인');
    System.debug('2. Upcoming & Overdue 섹션에서 연체 알림 Task 확인');
    System.debug('3. 관련된 이메일 수신 확인 (고객 및 관리자)');
    System.debug('4. Salesforce 상단 벨 아이콘 알림 확인');
    
    System.debug('✅ =====Order 00000115 테스트 완료=====');
    
} catch (Exception e) {
    System.debug('❌ Order 00000115 테스트 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

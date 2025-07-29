// 최종 Order 00000115 상태 확인
System.debug('🎯 Order 00000115 최종 상태 확인');

// Order 조회
List<Order> orders = [SELECT Id, OrderNumber, Account.Name FROM Order WHERE OrderNumber = '00000115'];
System.debug('📋 Order: ' + orders[0].OrderNumber + ' (' + orders[0].Account.Name + ')');

// PDF 파일 조회
List<ContentDocumentLink> pdfs = [
    SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.CreatedDate
    FROM ContentDocumentLink 
    WHERE LinkedEntityId = :orders[0].Id 
    AND ContentDocument.FileExtension = 'pdf'
    ORDER BY ContentDocument.CreatedDate DESC
    LIMIT 3
];

System.debug('📄 PDF 파일: ' + pdfs.size() + '개');
for (ContentDocumentLink pdf : pdfs) {
    System.debug('   • ' + pdf.ContentDocument.Title + '.pdf (생성: ' + pdf.ContentDocument.CreatedDate.format() + ')');
}

// Task 조회
List<Task> tasks = [
    SELECT Subject, Priority, Status, CreatedDate
    FROM Task 
    WHERE WhatId = :orders[0].Id 
    ORDER BY CreatedDate DESC 
    LIMIT 3
];

System.debug('📝 Task: ' + tasks.size() + '개');
for (Task task : tasks) {
    String today = task.CreatedDate.date() == Date.today() ? ' [오늘]' : '';
    System.debug('   • ' + task.Subject + ' (' + task.Priority + ', ' + task.Status + ')' + today);
}

System.debug('✅ 최종 상태 확인 완료');

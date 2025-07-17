// 간단한 PDF 첨부 테스트
System.debug('📎 Order 00000115 PDF 첨부 테스트');

// Order 조회
List<Order> orders = [SELECT Id, OrderNumber FROM Order WHERE OrderNumber = '00000115'];
if (orders.isEmpty()) {
    System.debug('❌ Order 없음');
    return;
}

Order order = orders[0];
System.debug('✅ Order: ' + order.OrderNumber + ' (ID: ' + order.Id + ')');

// PDF 파일 조회
List<ContentDocumentLink> pdfs = [
    SELECT ContentDocument.Id, ContentDocument.Title 
    FROM ContentDocumentLink 
    WHERE LinkedEntityId = :order.Id 
    AND ContentDocument.FileExtension = 'pdf'
    ORDER BY ContentDocument.CreatedDate DESC
];

System.debug('📄 PDF 파일: ' + pdfs.size() + '개');
for (ContentDocumentLink pdf : pdfs) {
    System.debug('   • ' + pdf.ContentDocument.Title + '.pdf');
}

if (!pdfs.isEmpty()) {
    // 최신 PDF의 ContentVersion 확인
    List<ContentVersion> cv = [
        SELECT Title, ContentSize, VersionData
        FROM ContentVersion 
        WHERE ContentDocumentId = :pdfs[0].ContentDocument.Id 
        AND IsLatest = true
    ];
    
    if (!cv.isEmpty()) {
        System.debug('📋 최신 PDF 정보:');
        System.debug('   제목: ' + cv[0].Title);
        System.debug('   크기: ' + (cv[0].ContentSize / 1024) + 'KB');
        System.debug('   데이터: ' + (cv[0].VersionData != null ? '있음' : '없음'));
        
        if (cv[0].VersionData != null) {
            System.debug('   실제 크기: ' + (cv[0].VersionData.size() / 1024) + 'KB');
        }
    }
}

System.debug('✅ PDF 상태 확인 완료');

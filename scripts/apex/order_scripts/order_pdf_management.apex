// Order 00000115 PDF 파일 확인 및 테스트 PDF 생성
System.debug('📎 =====Order 00000115 PDF 파일 관리=====');

try {
    // 1. Order 00000115 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, Account.Name
        FROM Order 
        WHERE OrderNumber = '00000115'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000115를 찾을 수 없습니다.');
        return;
    }
    
    Order targetOrder = orders[0];
    System.debug('📋 Order: ' + targetOrder.OrderNumber + ' (' + targetOrder.Account.Name + ')');
    System.debug('   Order ID: ' + targetOrder.Id);
    
    // 2. 현재 첨부된 모든 파일 확인
    List<ContentDocumentLink> allFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, 
               ContentDocument.CreatedDate, ContentDocument.ContentSize
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('📁 총 첨부 파일: ' + allFiles.size() + '개');
    for (ContentDocumentLink file : allFiles) {
        System.debug('   • ' + file.ContentDocument.Title + '.' + file.ContentDocument.FileExtension + 
                     ' (크기: ' + (file.ContentDocument.ContentSize / 1024) + 'KB, 생성일: ' + 
                     file.ContentDocument.CreatedDate.format() + ')');
    }
    
    // 3. PDF 파일만 필터링
    List<ContentDocumentLink> pdfFiles = [
        SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, 
               ContentDocument.CreatedDate
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :targetOrder.Id
        AND ContentDocument.FileExtension = 'pdf'
        ORDER BY ContentDocument.CreatedDate DESC
    ];
    
    System.debug('📄 PDF 파일: ' + pdfFiles.size() + '개');
    for (ContentDocumentLink pdf : pdfFiles) {
        System.debug('   • ' + pdf.ContentDocument.Title + '.pdf (생성일: ' + pdf.ContentDocument.CreatedDate.format() + ')');
    }
    
    // 4. PDF 파일이 없으면 테스트용 납부일정서 PDF 생성
    if (pdfFiles.isEmpty()) {
        System.debug('📝 테스트용 납부일정서 PDF 생성 중...');
        
        // 납부일정서 PDF 내용 생성
        String pdfContent = createPaymentSchedulePDF(targetOrder);
        
        // ContentVersion 생성
        ContentVersion cv = new ContentVersion();
        cv.Title = '납부일정서_' + targetOrder.OrderNumber + '_' + Date.today().format();
        cv.PathOnClient = cv.Title + '.pdf';
        cv.VersionData = Blob.valueOf(pdfContent);
        cv.ContentLocation = 'S';
        cv.Description = '0714TEST 고객 납부일정서 - ' + targetOrder.OrderNumber;
        insert cv;
        
        // ContentDocument ID 조회
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // ContentDocumentLink 생성 (Order에 연결)
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCV.ContentDocumentId;
        cdl.LinkedEntityId = targetOrder.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        System.debug('✅ 납부일정서 PDF 생성 완료: ' + cv.Title + '.pdf');
        System.debug('   ContentVersion ID: ' + cv.Id);
        System.debug('   ContentDocument ID: ' + insertedCV.ContentDocumentId);
        
        // 생성된 PDF 파일 목록 다시 조회
        pdfFiles = [
            SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, 
                   ContentDocument.CreatedDate
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :targetOrder.Id
            AND ContentDocument.FileExtension = 'pdf'
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        
        System.debug('📄 생성 후 PDF 파일: ' + pdfFiles.size() + '개');
    }
    
    // 5. 최신 PDF 파일 확인
    if (!pdfFiles.isEmpty()) {
        ContentDocumentLink latestPDF = pdfFiles[0];
        System.debug('📎 최신 PDF: ' + latestPDF.ContentDocument.Title + '.pdf');
        System.debug('   생성일: ' + latestPDF.ContentDocument.CreatedDate.format());
        System.debug('   ContentDocument ID: ' + latestPDF.ContentDocument.Id);
        
        // ContentVersion 상세 정보 조회
        List<ContentVersion> cvDetails = [
            SELECT Id, Title, VersionData, ContentSize, Description
            FROM ContentVersion 
            WHERE ContentDocumentId = :latestPDF.ContentDocument.Id
            AND IsLatest = true
            LIMIT 1
        ];
        
        if (!cvDetails.isEmpty()) {
            ContentVersion cv = cvDetails[0];
            System.debug('   파일 크기: ' + (cv.ContentSize / 1024) + 'KB');
            System.debug('   설명: ' + cv.Description);
            System.debug('   데이터 크기: ' + (cv.VersionData != null ? (cv.VersionData.size() / 1024) + 'KB' : '없음'));
        }
    }
    
    System.debug('✅ =====Order 00000115 PDF 파일 관리 완료=====');
    
} catch (Exception e) {
    System.debug('❌ PDF 파일 관리 오류: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// 납부일정서 PDF 내용 생성 함수
private static String createPaymentSchedulePDF(Order orderInfo) {
    // 실제 PDF는 복잡하지만, 테스트용으로 간단한 PDF 구조 생성
    String pdfContent = '%PDF-1.4\n';
    pdfContent += '1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n\n';
    pdfContent += '2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n\n';
    pdfContent += '3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n\n';
    pdfContent += '4 0 obj\n<<\n/Length 200\n>>\nstream\n';
    pdfContent += 'BT\n/F1 12 Tf\n100 700 Td\n';
    pdfContent += '(납부일정서 - Order: ' + orderInfo.OrderNumber + ') Tj\n';
    pdfContent += '0 -20 Td\n(고객명: ' + orderInfo.Account.Name + ') Tj\n';
    pdfContent += '0 -20 Td\n(생성일: ' + Date.today().format() + ') Tj\n';
    pdfContent += '0 -40 Td\n(1차: 8,333,333원 - 2025.07.14 완납) Tj\n';
    pdfContent += '0 -20 Td\n(2차: 8,333,333원 - 2025.08.14 예정) Tj\n';
    pdfContent += '0 -20 Td\n(3차: 8,333,333원 - 2025.09.14 예정) Tj\n';
    pdfContent += 'ET\nendstream\nendobj\n\n';
    pdfContent += 'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n';
    pdfContent += '0000000115 00000 n \n0000000204 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\n';
    pdfContent += 'startxref\n456\n%%EOF';
    
    return pdfContent;
}

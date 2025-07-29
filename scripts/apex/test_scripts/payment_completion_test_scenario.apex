/**
 * 완납 시나리오 테스트 실행 스크립트
 * Developer Console > Debug > Open Execute Anonymous Window에서 실행
 * 
 * 테스트 시나리오:
 * 1. 특정 Order의 현재 납부 상태 확인
 * 2. 모든 PaymentStatus를 완납으로 변경
 * 3. 납부 일정 타임라인 자동 완납 상태 반영 확인
 * 4. 납부확인서 + 세금계산서 PDF 생성 테스트
 */

System.debug('🎯 =====완납 시나리오 테스트 스크립트 시작=====');

try {
    // 1. 테스트할 Order 선택 (가장 최근의 PaymentStatus가 있는 Order)
    List<Order> testOrders = [
        SELECT Id, OrderNumber, TotalAmount, Account.Name,
               (SELECT Id FROM PaymentStatus__c WHERE Status__c != '완납' LIMIT 1)
        FROM Order 
        WHERE Id IN (SELECT Order__c FROM PaymentStatus__c WHERE Status__c != '완납')
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    
    if (testOrders.isEmpty()) {
        System.debug('❌ 미납 상태의 PaymentStatus가 있는 Order를 찾을 수 없습니다.');
        System.debug('📝 테스트 데이터 생성이 필요합니다.');
        return;
    }
    
    Order testOrder = testOrders[0];
    System.debug('📋 테스트 대상 Order: ' + testOrder.OrderNumber);
    System.debug('   고객명: ' + testOrder.Account.Name);
    System.debug('   주문 금액: ₩' + testOrder.TotalAmount?.format());
    
    // 2. 완납 시나리오 테스트 실행
    String testResult = PaymentCompletionTestService.executePaymentCompletionTest(testOrder.Id);
    
    // 3. 결과 출력
    System.debug('');
    System.debug(testResult);
    
    // 4. 추가 검증: 타임라인 데이터 확인
    System.debug('');
    System.debug('🔍 =====타임라인 데이터 최종 검증=====');
    
    PaymentStatusTimelineController.PaymentTimelineWrapper timelineData = 
        PaymentStatusTimelineController.getPaymentTimeline(testOrder.Id);
    
    System.debug('타임라인 진행률: ' + timelineData.progressPercentage + '%');
    System.debug('완납 항목: ' + timelineData.completedInstallments + '/' + timelineData.totalInstallments);
    System.debug('연체 항목: ' + timelineData.overdueInstallments + '개');
    
    if (timelineData.progressPercentage == 100) {
        System.debug('✅ 타임라인에서 100% 완납 상태 확인됨');
    } else {
        System.debug('⚠️ 타임라인 완납률: ' + timelineData.progressPercentage + '%');
    }
    
    // 5. 생성된 PDF 파일 확인
    System.debug('');
    System.debug('📄 =====생성된 PDF 파일 확인=====');
    List<ContentVersion> todayPDFs = [
        SELECT Id, Title, ContentSize, CreatedDate
        FROM ContentVersion
        WHERE FirstPublishLocationId = :testOrder.Id
        AND CreatedDate = TODAY
        ORDER BY CreatedDate DESC
    ];
    
    if (todayPDFs.isEmpty()) {
        System.debug('⚠️ 오늘 생성된 PDF 파일이 없습니다.');
    } else {
        System.debug('📄 오늘 생성된 PDF 파일: ' + todayPDFs.size() + '개');
        
        Integer paymentPdfCount = 0;
        Integer taxPdfCount = 0;
        
        for (ContentVersion pdf : todayPDFs) {
            String fileType = '';
            if (pdf.Title.contains('납부확인서')) {
                fileType = '[납부확인서]';
                paymentPdfCount++;
            } else if (pdf.Title.contains('세금계산서')) {
                fileType = '[세금계산서]';
                taxPdfCount++;
            }
            
            System.debug('   • ' + pdf.Title + ' ' + fileType);
            System.debug('     크기: ' + (pdf.ContentSize/1024) + 'KB, 생성: ' + pdf.CreatedDate.format());
        }
        
        // PDF 생성 결과 검증
        if (paymentPdfCount > 0 && taxPdfCount > 0) {
            System.debug('✅ 납부확인서 + 세금계산서 모두 생성됨');
        } else if (paymentPdfCount > 0) {
            System.debug('⚠️ 납부확인서만 생성됨 (세금계산서 누락)');
        } else {
            System.debug('❌ PDF 생성 실패');
        }
    }
    
    System.debug('');
    System.debug('🎯 =====완납 시나리오 테스트 스크립트 완료=====');
    System.debug('');
    System.debug('📋 확인사항:');
    System.debug('1. Order ' + testOrder.OrderNumber + ' 페이지에서 납부 일정 타임라인 확인');
    System.debug('2. Files 섹션에서 납부확인서 + 세금계산서 PDF 다운로드 확인');
    System.debug('3. Activity Timeline에서 완납 Task 생성 확인');
    
} catch (Exception e) {
    System.debug('❌ 테스트 실행 중 오류 발생: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('🎯 =====스크립트 실행 완료=====');

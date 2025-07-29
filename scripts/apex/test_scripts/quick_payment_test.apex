/**
 * 빠른 완납 테스트 스크립트
 * Developer Console에서 실행
 */

System.debug('🎯 빠른 완납 테스트 시작');

try {
    // 테스트할 Order 하나 선택
    List<Order> orders = [
        SELECT Id, OrderNumber 
        FROM Order 
        WHERE Id IN (SELECT Order__c FROM PaymentStatus__c WHERE Status__c != '완납')
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ 테스트할 Order를 찾을 수 없습니다.');
        return;
    }
    
    Id testOrderId = orders[0].Id;
    System.debug('📋 테스트 Order: ' + orders[0].OrderNumber);
    
    // STEP 1: 완납 처리
    String result = PaymentStatusTimelineController.markAllPaymentsAsCompleted(testOrderId);
    System.debug('완납 처리: ' + result);
    
    // STEP 2: PDF 생성 (납부확인서 + 세금계산서)
    String pdfId = PaymentStatusTimelineController.generatePaymentSchedulePDF(testOrderId);
    System.debug('PDF 생성: ' + pdfId);
    
    // STEP 3: 결과 확인
    PaymentStatusTimelineController.PaymentTimelineWrapper timeline = 
        PaymentStatusTimelineController.getPaymentTimeline(testOrderId);
    
    System.debug('✅ 최종 결과:');
    System.debug('   완납률: ' + timeline.progressPercentage + '%');
    System.debug('   완납 항목: ' + timeline.completedInstallments + '/' + timeline.totalInstallments);
    
    if (timeline.progressPercentage == 100) {
        System.debug('🎉 테스트 성공: 타임라인이 완납 상태로 업데이트됨');
    }
    
} catch (Exception e) {
    System.debug('❌ 오류: ' + e.getMessage());
}

System.debug('🎯 빠른 완납 테스트 완료');

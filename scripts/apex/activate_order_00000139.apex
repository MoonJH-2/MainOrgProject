/**
 * Order 00000139 상태 활성화 스크립트
 * Developer Console > Debug > Open Execute Anonymous Window에서 실행
 * 
 * 목표: Order Product가 등록된 Order의 Status를 Draft → Activated로 변경
 */

System.debug('🎯 =====Order 00000139 상태 활성화 시작=====');

try {
    // 1. Order 00000139 조회
    Order targetOrder = [
        SELECT Id, OrderNumber, Status, TotalAmount, OpportunityId
        FROM Order 
        WHERE OrderNumber = '00000139' 
        LIMIT 1
    ];
    
    System.debug('📋 Order 정보:');
    System.debug('   OrderNumber: ' + targetOrder.OrderNumber);
    System.debug('   현재 Status: ' + targetOrder.Status);
    System.debug('   TotalAmount: ₩' + targetOrder.TotalAmount);
    
    // 2. Order Products 확인
    List<OrderItem> orderProducts = [
        SELECT Id, Product2.Name, Quantity, UnitPrice
        FROM OrderItem 
        WHERE OrderId = :targetOrder.Id
    ];
    
    System.debug('');
    System.debug('📦 Order Products 현황:');
    System.debug('   개수: ' + orderProducts.size());
    
    for (OrderItem item : orderProducts) {
        System.debug('   - ' + item.Product2.Name + ' x ' + item.Quantity + ' (₩' + item.UnitPrice + ')');
    }
    
    // 3. PaymentStatus 확인
    List<PaymentStatus__c> paymentStatuses = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        ORDER BY InstallmentNumber__c
    ];
    
    System.debug('');
    System.debug('💰 PaymentStatus 현황:');
    System.debug('   개수: ' + paymentStatuses.size());
    
    for (PaymentStatus__c ps : paymentStatuses) {
        System.debug('   - ' + ps.InstallmentNumber__c + '차: ₩' + ps.Amount__c + ' (' + ps.Status__c + ', due: ' + ps.DueDate__c + ')');
    }
    
    // 4. Order 상태 확인 및 변경
    if (targetOrder.Status == 'Draft' && !orderProducts.isEmpty()) {
        System.debug('');
        System.debug('🔄 Order 상태 변경 중...');
        
        targetOrder.Status = 'Activated';
        update targetOrder;
        
        System.debug('✅ Order 상태 변경 완료: Draft → Activated');
        
        // 5. PaymentStatus 첫 번째 건을 연체 상태로 변경 (화면과 일치시키기 위해)
        if (!paymentStatuses.isEmpty()) {
            PaymentStatus__c firstPayment = paymentStatuses[0];
            if (firstPayment.Status__c == '미납') {
                firstPayment.Status__c = '연체';
                update firstPayment;
                System.debug('✅ 1차 PaymentStatus 상태 변경: 미납 → 연체');
            }
        }
        
    } else if (targetOrder.Status == 'Activated') {
        System.debug('');
        System.debug('ℹ️ Order는 이미 Activated 상태입니다.');
    } else if (orderProducts.isEmpty()) {
        System.debug('');
        System.debug('❌ Order Products가 없어서 활성화할 수 없습니다.');
        
        // Order Products 자동 등록 시도
        if (targetOrder.OpportunityId != null) {
            System.debug('🔧 Opportunity Product 자동 등록 시도...');
            OrderProductAutoRegistrationService.registerOpportunityProducts(targetOrder.Id);
            System.debug('✅ Opportunity Product 자동 등록 완료');
        }
    }
    
    // 6. 최종 상태 확인
    Order finalOrder = [
        SELECT Id, OrderNumber, Status, TotalAmount
        FROM Order 
        WHERE Id = :targetOrder.Id
    ];
    
    List<OrderItem> finalProducts = [
        SELECT Id FROM OrderItem WHERE OrderId = :targetOrder.Id
    ];
    
    List<PaymentStatus__c> finalPayments = [
        SELECT Id, Status__c FROM PaymentStatus__c WHERE Order__c = :targetOrder.Id
    ];
    
    System.debug('');
    System.debug('🎯 =====최종 결과=====');
    System.debug('✅ Order Number: ' + finalOrder.OrderNumber);
    System.debug('✅ Status: ' + finalOrder.Status);
    System.debug('✅ TotalAmount: ₩' + finalOrder.TotalAmount);
    System.debug('✅ Order Products: ' + finalProducts.size() + '개');
    System.debug('✅ PaymentStatus: ' + finalPayments.size() + '개');
    
    // 연체 상태 확인
    Integer overdueCount = 0;
    for (PaymentStatus__c ps : finalPayments) {
        if (ps.Status__c == '연체') {
            overdueCount++;
        }
    }
    System.debug('✅ 연체 건수: ' + overdueCount + '개');
    
    System.debug('');
    System.debug('🔍 확인사항:');
    System.debug('1. Order 00000139 페이지 새로고침');
    System.debug('2. Order Status가 Activated로 표시되는지 확인');
    System.debug('3. 납부 일정 타임라인에서 1차가 연체로 표시되는지 확인');
    
} catch (Exception e) {
    System.debug('❌ 오류 발생: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('🎯 =====스크립트 실행 완료=====');
